type path = string list

type route = Httpaf.Method.t * path
type 'ctx service = 'ctx Request.t -> Response.t Lwt.t
type ('ctx1, 'ctx2) filter = 'ctx1 service -> 'ctx2 service
type 'ctx t = route -> 'ctx service

let scope = (|>)
let filter f = f

let parse_route {Httpaf.Request.meth; target; _} =
  meth, target |> String.split_on_char '/' |> List.tl

let error_handler _client_addr ?(request) _error _start_resp =
  ignore request;
  failwith "!"

let serve ?(port=8080) server =
  let open Lwt_let in

  let request_handler _client_addr reqd =
    let route = reqd |> Httpaf.Reqd.request |> parse_route in
    let request = Request.make reqd in
    server route request
  in
  let conn_handler = Httpaf_lwt.Server.create_connection_handler
    ~request_handler
    ~error_handler
  in
  let listen_addr = Unix.(ADDR_INET (inet_addr_loopback, port)) in
  let* lwt_server =
    Lwt_io.establish_server_with_client_socket listen_addr conn_handler
  in
  let forever, _ = Lwt.wait () in
  forever
