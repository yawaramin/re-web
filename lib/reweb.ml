(** Reweb - an ergonomic web framework. Start by looking at {!module:Server} for
    an overview of the framework. See [bin/main.ml] for an example server.
    
    See {{: https://github.com/yawaramin/re-web/}} for sources. *)

module Form = Form
(** Encode and decode web forms to/from specified types. *)

module Response = Response
(** Send responses. *)

module H = Httpaf

module Reqd = struct
  module Body = H.Body
  include H.Reqd
end

module Request = Request.Make(Reqd)
module Service = Service.Make(Request)
module Filter = Filter.Make(Request)

type path = string list
type route = H.Method.t * path
type 'ctx server = sw:Eio.Switch.t -> route -> 'ctx Service.t

let not_found _ = Response.of_status `Not_found
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
  let open Reweb_header.CacheControl in
  let no_store = Filter.cache_control No_store in
  function
  | `GET, ([] | [""]) ->
    index
  | `POST, [] ->
    no_store create
  | `GET, (["new"] | ["new"; ""]) ->
    Filter.cache_control (public ~max_age:one_wk ()) new_
  | `GET, ([id; "edit"] | [id; "edit"; ""]) ->
    edit id
  | `GET, ([id] | [id; ""]) ->
    show id
  | `Other "PATCH", [id] ->
    no_store @@ update `PATCH id
  | `PUT, [id] ->
    no_store @@ update `PUT id
  | `DELETE, [id] ->
    no_store @@ destroy id
  | _ ->
    not_found

let segment path = path |> String.split_on_char '/' |> List.tl

let parse_route { H.Request.meth; target; _ } =
  Eio.traceln "REQ: %s %s%!" (H.Method.to_string meth) target;
  match String.split_on_char '?' target with
  | [path; query] -> meth, segment path, query
  | [path] -> meth, segment path, ""
  | _ -> failwith "ReWeb.Server: failed to parse route"

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

let filter server ~sw route =
  begin
    if Reweb_cfg.filter_csp
    then [] |> Reweb_header.ContentSecurityPolicy.make |> Filter.csp
    else Fun.id
  end
  @@
  begin
    if Reweb_cfg.filter_hsts
    then two_years |> Reweb_header.StrictTransportSecurity.make |> Filter.hsts
    else Fun.id
  end
  @@
  server ~sw route

(* let sha1 string = Digestif.SHA1.(string |> digest_string |> to_raw_string) *)

let listen_addr = `Tcp (Eio.Net.Ipaddr.V4.any, Reweb_cfg.port)

let main net domain_mgr server =
  let request_handler client_addr reqd =
    let respond (resp, body) =
      let code = H.Status.to_code resp.H.Response.status in
      Eio.traceln "REP: %d %a" code Eio.Net.Sockaddr.pp client_addr;
      resp
      |> H.Reqd.respond_with_streaming reqd
      |> Body.to_sink
      |> Eio.Flow.copy body
    in
    (* Will report error if fails *)
    ignore @@ H.Reqd.try_with reqd @@ fun () ->
    let meth, path, query = reqd |> H.Reqd.request |> parse_route in
    let server = filter server in
    Eio.Switch.run @@ fun sw ->
    reqd |> Request.make query |> server ~sw (meth, path) |> respond
  in
  let conn_handler = Httpaf_eio.Server.create_connection_handler
    ~error_handler
    request_handler
  in
  Eio.Switch.run @@ fun sw ->
  let listen_socket = Eio.Net.listen ~backlog:128 ~sw net listen_addr in
  Eio.traceln "Reweb: listening on %a" Eio.Net.Sockaddr.pp listen_addr;
  let new_domain = Eio.Domain_manager.run domain_mgr in
  let domain_loop () =
    new_domain @@ fun () ->
    Eio.Switch.run @@ fun sw ->
    while true do
      Eio.Net.accept_fork
        ~sw
        listen_socket
        ~on_error:(fun exn ->
          Eio.traceln
            "Connection handling error: %a"
            Fmt.exn_backtrace
            (exn, Printexc.get_raw_backtrace ()))
        conn_handler
    done
  in
  Eio.Fiber.all @@ List.init Reweb_cfg.num_threads @@ fun _ -> domain_loop
