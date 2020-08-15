module H = Httpaf

module Reqd = struct
  module Body = H.Body
  include H.Reqd
end

module Config = ReWeb__Config
module Header = ReWeb__Header
module Request = Request.Make(ReWeb__Config.Default)(Reqd)
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
      queue_incoming (Some (Ok (Bigstringaf.substring ~off ~len bigstring)))
    | `Connection_close ->
      queue_incoming (Some (Error `Connection_close));
      queue_incoming None;
      eof ()
    | `Ping -> Wsd.send_pong wsd
    | `Pong
    | `Other _ -> ()
  in
  let pull timeout_s =
    let msg = incoming
      |> Lwt_stream.get
      |> Lwt.map @@ function
        | Some msg -> msg
        | None -> Error `Empty
    in
    Lwt.pick [
      msg;
      timeout_s |> Lwt_unix.sleep |> Lwt.map @@ fun () -> Error `Timeout;
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

let upgrade_handler addr upgrade handler () =
  let promise, resolver = Lwt.wait () in
  let ws_conn = Websocketaf.Server_connection.create_websocket
    ~error_handler
    (websocket_handler handler resolver addr)
  in
  ws_conn
  |> Gluten.make (module Websocketaf.Server_connection)
  |> upgrade;

  Lwt.on_success promise @@ fun result ->
    print_endline @@ match result with
      | Ok () ->
        addr
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

let filter server route =
  begin
    if Config.Default.Filters.csp
    then [] |> Header.ContentSecurityPolicy.make |> Filter.csp
    else Fun.id
  end
  @@
  begin
    if Config.Default.Filters.hsts
    then two_years |> Header.StrictTransportSecurity.make |> Filter.hsts
    else Fun.id
  end
  @@
  server route

let sha1 string = Digestif.SHA1.(string |> digest_string |> to_raw_string)

let serve ~port server =
  let request_handler client_addr { Gluten.Reqd.reqd; upgrade } =
    let f () =
      let send = function
        | `HTTP (resp, body) ->
          let code = H.Status.to_code resp.H.Response.status in
          client_addr
          |> string_of_unix_addr
          |> Printf.printf " %d %s\n%!" code;

          let writer = H.Reqd.respond_with_streaming reqd resp in
          let result = Piaf.Body.iter (schedule_chunk writer) body in
          Lwt.on_success result begin function
            | Ok () -> H.Body.close_writer writer
            | Error error ->
              Reqd.report_exn reqd (Failure (Piaf.Error.to_string error));
              H.Body.close_writer writer
          end
        | `WebSocket (headers, handler) ->
          print_string " ";
          client_addr |> string_of_unix_addr |> print_endline;
          begin match Websocketaf.Handshake.respond_with_upgrade
            ?headers
            ~sha1
            reqd
            (upgrade_handler client_addr upgrade handler) with
            | Ok () -> ()
            | Error string ->
              let headers = H.Headers.of_list ["connection", "close"] in
              let response = H.Response.create ~headers `Bad_request in
              Reqd.respond_with_string reqd response string
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
  let listen_addr = Unix.(ADDR_INET (inet_addr_any, port)) in
  let open Lwt.Syntax in
  let* _ =
    Lwt_io.establish_server_with_client_socket listen_addr conn_handler
  in
  let* () = Lwt_io.printf "ReWeb.Server: listening on port %d\n" port in
  let forever, _ = Lwt.wait () in
  forever

let serve ?(port=Config.Default.port) server = server |> serve ~port |> Lwt_main.run

