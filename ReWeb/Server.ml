module H = Httpaf
module Wsd = Websocketaf.Wsd

type path = string list
type route = H.Method.t * path
type ('ctx, 'resp) service = 'ctx Request.t -> 'resp Response.t Lwt.t
type ('ctx, 'resp) t = route -> ('ctx, 'resp) service

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
  let incoming, queue_incoming = Lwt_stream.create () in
  let eof () = Wsd.close wsd in
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
  let pull () = Lwt_stream.get incoming in
  let push = function
    | Some string ->
      let off = 0 in
      let len = String.length string in
      let bigstring = Bigstringaf.of_string ~off ~len string in
      Wsd.schedule wsd bigstring ~kind:`Text ~off ~len
    | None -> eof ()
  in
  Lwt.on_success (handler pull push) begin fun () ->
    Lwt.wakeup_later resolver (Ok ())
  end;

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
  let result =
    let promise, resolver = Lwt.wait () in
    let open Let.Lwt in
    let* _ = client_addr
      |> Websocketaf_lwt_unix.Server.create_upgraded_connection_handler
        ~error_handler
        ~websocket_handler:(websocket_handler handler resolver)
      |> Websocketaf_lwt_unix.Server.respond_with_upgrade ?headers reqd
    in
    promise
  in
  Lwt.on_success result @@ fun result ->
    print_endline @@ match result with
      | Ok () -> "ReWeb.Server: WebSocket shutting down"
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

let serve ?(port=8080) server =
  let request_handler client_addr reqd =
    let send = function
      | `HTTP { Response.envelope; body } ->
        let code = H.Status.to_code envelope.H.Response.status in
        client_addr
        |> string_of_unix_addr
        |> Printf.printf " %d %s\n%!" code;

        let send stream =
          let writer = H.Reqd.respond_with_streaming reqd envelope in
          let fully_written =
            Lwt_stream.iter (schedule_chunk writer) stream
          in
          Lwt.on_success fully_written @@ fun _ ->
            H.Body.close_writer writer
        in
        begin match body with
        | Body.Bigstring bigstring ->
          H.Reqd.respond_with_bigstring reqd envelope bigstring
        | Body.Chunks stream -> send stream
        | Body.Piaf body -> body |> to_stream |> send
        | Body.String string ->
          H.Reqd.respond_with_string reqd envelope string
        end
      | `WebSocket (headers, handler) ->
        print_string " ";
        client_addr |> string_of_unix_addr |> print_endline;

        websocket_upgrader ?headers reqd client_addr handler
    in
    let meth, path, query = reqd |> H.Reqd.request |> parse_route in
    let response = reqd |> Request.make query |> server (meth, path) in
    Lwt.on_success response send;
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

