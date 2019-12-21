module H = Httpaf

type path = string list
type route = H.Method.t * path
type 'ctx service = 'ctx Request.t -> Response.t Lwt.t
type 'ctx t = route -> 'ctx service

let parse_route {H.Request.meth; target; _} =
  meth, target |> String.split_on_char '/' |> List.tl

let schedule_chunk writer {H.IOVec.off; len; buffer} =
  H.Body.schedule_bigstring writer ~off ~len buffer

let error_handler _client_addr ?(request) _error _start_resp =
  ignore request;
  failwith "!"

let serve ?(port=8080) server =
  let request_handler _client_addr reqd =
    let route = reqd |> H.Reqd.request |> parse_route in
    let response = reqd |> Request.make |> server route in
    let send {Response.envelope; body; _} = match body with
      | Body.Single bigstring ->
        H.Reqd.respond_with_bigstring reqd envelope bigstring
      | Body.Multi stream ->
        let writer = H.Reqd.respond_with_streaming reqd envelope in
        stream
        |> Lwt_stream.iter (schedule_chunk writer)
        |> Lwt.map (fun _ -> H.Body.close_writer writer)
        |> ignore
    in
    Lwt.on_success response send
  in
  let conn_handler = Httpaf_lwt_unix.Server.create_connection_handler
    ~request_handler
    ~error_handler
  in
  let listen_addr = Unix.(ADDR_INET (inet_addr_loopback, port)) in
  let open Lwt_let in
  let* lwt_server =
    Lwt_io.establish_server_with_client_socket listen_addr conn_handler
  in
  let* () = Lwt_io.printf "Server listening on port %d\n" port in
  let forever, _ = Lwt.wait () in
  forever
