module H = Httpaf

module Reqd = struct
  module Body = H.Body
  include H.Reqd
end

module Config = ReWeb__Config
module Header = ReWeb__Header
module Request = Request.Make(ReWeb__Config.Default)(H.Body)(Reqd)
module Service = Service.Make(Request)
module Filter = Filter.Make(Request)
module Wsd = Websocketaf.Wsd

type path = string list
type route = H.Method.t * path
type ('ctx, 'resp) t = route -> ('ctx, 'resp) Service.t

let not_found _ = `Not_found |> Response.of_status |> Lwt.return
let not_found_id _ = not_found
let one_wk = 7 * 24 * 60 * 60

let resource
  ?(index=not_found)
  ?(create=not_found)
  ?(new_=not_found)
  ?(edit=not_found_id)
  ?(show=not_found_id)
  ?(update=fun _ -> not_found_id)
  ?(destroy=not_found_id) =
  let open Header.CacheControl in
  let no_store = Filter.cache_control No_store in
  function
  | `GET, ([] | [""]) -> index
  | `POST, [] -> no_store create
  | `GET, (["new"] | ["new"; ""]) ->
    Filter.cache_control (public ~max_age:one_wk ()) new_
  | `GET, ([id; "edit"] | [id; "edit"; ""]) -> edit id
  | `GET, ([id] | [id; ""]) -> show id
  | `Other "PATCH", [id] -> no_store @@ update `PATCH id
  | `PUT, [id] -> no_store @@ update `PUT id
  | `DELETE, [id] -> no_store @@ destroy id
  | _ -> not_found

let segment path = path |> String.split_on_char '/' |> List.tl

let parse_route { H.Request.meth; target; _ } =
  Printf.printf "ReWeb.Server: %s %s%!" (H.Method.to_string meth) target;

  match String.split_on_char '?' target with
  | [path; query] -> meth, segment path, query
  | [path] -> meth, segment path, ""
  | _ -> failwith "ReWeb.Server: failed to parse route"

let string_of_unix_addr = function
  | Unix.ADDR_UNIX string -> string
  | Unix.ADDR_INET (inet_addr, _) -> Unix.string_of_inet_addr inet_addr

let schedule_chunk writer { H.IOVec.off; len; buffer } =
  H.Body.schedule_bigstring writer ~off ~len buffer

let to_stream body = body
  |> Piaf.Body.to_stream
  |> Lwt_stream.map Body.make_chunk

let websocket_handler handler resolver _ wsd =
  let resolve () =
    try Lwt.wakeup_later resolver (Ok ())
    with _ -> ()
  in
  let incoming, queue_incoming = Lwt_stream.create () in
  let eof () =
    Wsd.close wsd;
    resolve ()
  in
  let frame ~opcode ~is_fin:_ bigstring ~off ~len = match opcode with
    | `Continuation
    | `Text
    | `Binary ->
      bigstring
      |> Bigstringaf.substring ~off ~len
      |> Option.some
      |> queue_incoming
    | `Connection_close -> eof ()
    | `Ping -> Wsd.send_pong wsd
    | `Pong
    | `Other _ -> ()
  in
  let pull timeout_s = Lwt.pick [
    Lwt_stream.get incoming;
    timeout_s |> Lwt_unix.sleep |> Lwt.map @@ fun () -> None;
  ]
  in
  let push string =
    let off = 0 in
    let len = String.length string in
    let bigstring = Bigstringaf.of_string ~off ~len string in
    Wsd.schedule wsd bigstring ~kind:`Binary ~off ~len
  in
  Lwt.on_success (handler pull push) resolve;

  { Websocketaf.Server_connection.frame; eof }

let error_handler wsd (`Exn exn) =
  let message = Printexc.to_string exn in
  let payload = Bytes.of_string message in
  Wsd.send_bytes
    wsd
    ~kind:`Text
    payload
    ~off:0
    ~len:(Bytes.length payload);

  Wsd.close wsd

let websocket_upgrader ?headers reqd client_addr handler =
  let promise, resolver = Lwt.wait () in
  let upgrade_result = client_addr
    |> Websocketaf_lwt_unix.Server.create_upgraded_connection_handler
      ~error_handler
      ~websocket_handler:(websocket_handler handler resolver)
    |> Websocketaf_lwt_unix.Server.respond_with_upgrade ?headers reqd
  in
  Lwt.on_success promise @@ fun result ->
    print_endline @@ match result with
      | Ok () ->
        Lwt.cancel upgrade_result;
        client_addr
        |> string_of_unix_addr
        |> ((^) "ReWeb.Server: WebSocket closed ")
      | Error string -> string

let error_handler _ ?request:_ error handle =
  let message = match error with
    | `Exn exn -> Printexc.to_string exn
    | (#H.Status.client_error | #H.Status.server_error) as error ->
      H.Status.to_string error
  in
  let body = handle H.Headers.empty in
  H.Body.write_string body message;
  H.Body.close_writer body

let two_years = 2 * 365 * 24 * 60 * 60
let id x = x

let filter server route =
  begin
    if Config.Default.Filters.csp
    then [] |> Header.ContentSecurityPolicy.make |> Filter.csp
    else id
  end
  @@
  begin
    if Config.Default.Filters.hsts
    then two_years |> Header.StrictTransportSecurity.make |> Filter.hsts
    else id
  end
  @@
  server route

let serve ~port server =
  let request_handler client_addr reqd =
    let f () =
      let send = function
        | `HTTP (resp, body) ->
          let code = H.Status.to_code resp.H.Response.status in
          client_addr
          |> string_of_unix_addr
          |> Printf.printf " %d %s\n%!" code;

          let send stream =
            let writer = H.Reqd.respond_with_streaming reqd resp in
            let fully_written =
              Lwt_stream.iter (schedule_chunk writer) stream
            in
            Lwt.on_success fully_written @@ fun _ ->
              H.Body.close_writer writer
          in
          begin match body with
          | Body.Bigstring bigstring ->
            H.Reqd.respond_with_bigstring reqd resp bigstring
          | Body.Chunks stream -> send stream
          | Body.Piaf body -> body |> to_stream |> send
          | Body.String string ->
            H.Reqd.respond_with_string reqd resp string
          end
        | `WebSocket (headers, handler) ->
          print_string " ";
          client_addr |> string_of_unix_addr |> print_endline;
          begin
            try websocket_upgrader ?headers reqd client_addr handler with
            | exn -> Reqd.report_exn reqd exn
          end
      in
      let meth, path, query = reqd |> H.Reqd.request |> parse_route in
      let server = filter server in
      let response = reqd |> Request.make query |> server (meth, path) in
      Lwt.on_success response send
    in
    (* Will report error if fails *)
    f |> H.Reqd.try_with reqd |> ignore
  in
  let conn_handler = Httpaf_lwt_unix.Server.create_connection_handler
    ~request_handler
    ~error_handler
  in
  let listen_addr = Unix.(ADDR_INET (inet_addr_loopback, port)) in
  let open Let.Lwt in
  let* _ =
    Lwt_io.establish_server_with_client_socket listen_addr conn_handler
  in
  let* () = Lwt_io.printf "ReWeb.Server: listening on port %d\n" port in
  let forever, _ = Lwt.wait () in
  forever

let serve ?(port=8080) server = server |> serve ~port |> Lwt_main.run

