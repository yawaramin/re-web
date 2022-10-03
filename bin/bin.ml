(* This is an example that shows the various features of ReWeb for creating web
   servers. You can skip to the bottom of the file to see the router, and work
   your way back up if you want. *)

(* [Reweb] contains just a handful of modules so there's very little
   chance of a conflict. *)
open Reweb

(** [not_found request] is a service that responds with a formatted HTML
    404 Not Found message. *)
let not_found  _ =
  Response.of_html ~status:`Not_found {|<!doctype html>
<html>
  <head>
    <meta charset="utf-8">
    <title>Not Found</title>
  </head>
  <body>
    <h1>Not Found</h1>
  </body>
</html>|}

(** [hello request] is a service that just responds with a hello-world message. *)
let hello _ = Response.of_text "Hello, World!"

(** [get_header name request] is a service that returns the contents of the
    [request] header named [name]. *)
let get_header name request =
  match Request.header name request with
  | Some value ->
    value
    |> Printf.sprintf
      {|<h1>GET /header/%s</h1>
<p>%s</p>|}
      name
    |> Response.of_html
  | None ->
    not_found request

(** [get_static dir filename request] is a service that returns the contents of
    [dir]/[filename] (if found). *)
let get_static ~sw dir filename _ = Response.of_file ~sw dir filename

(** [echo_body request] is a service that directly echoes the [request] body back
    to the client, without touching it at all. *)
let echo_body request = request
  |> Request.body
  |> Response.of_flow
    ~status:`OK
    ~headers:[
      "content-type", "application/octet-stream";
      "connection", "close";
    ]

(** [exclaim_body request] is a service that echoes the [request] body but with
    an exclamation mark added to the end. *)
let exclaim_body request = Response.of_text (Request.body_string request ^ "!")

(** [auth_hello request] is a service that handles [GET /auth/hello].  It's
    statically guaranteed to access the credentials in the request context
    (because the filter was applied in the top-level server). *)
let auth_hello request =
  let context = Request.context request in
  context#password
  |> Printf.sprintf "Username = %s\nPassword = %s" context#username
  |> Response.of_text

(* Server for /auth/... endpoints, enforcing basic auth (see below) *)
let auth_server = function
  | `GET, ["hello"] -> auth_hello
  | _ -> not_found

let msie = Str.regexp ".*MSIE.*"

(* Filter that rejects requests from MSIE *)
let reject_explorer next request = match Request.header "user-agent" request with
  | Some ua when Str.string_match msie ua 0 ->
    Response.of_status ~message:"Please upgrade your browser" `Unauthorized
  | _ ->
    next request

(* The top-level server (which is also a router simply by using pattern-
   matching syntax). In the filter examples below which use [@@] you can
   think of it as 'and' or 'then', i.e. 'first apply this filter then
   send the request to the service'. Actually [@@] is a generic operator
   provided by the standard library: [f x @@ y == f x y]. *)
let server dir ~sw = function
  | `GET, ["hello"] -> hello
  | `GET, ["header"; name] -> get_header name
  (* Applies a filter to the [GET /login-query] endpoint to decode the
     request query to the same form as above. For demo purposes only,
     obviously we won't be sending login credentials in the query in
     real code :-) *)
  | `GET, "static" :: filename -> get_static ~sw dir @@ String.concat "/" filename
  | `POST, ["body"] -> echo_body
  | `POST, ["body-bang"] -> exclaim_body
  (* Applies a filter to the [POST /json] endpoint to parse the request
     body as JSON. Returns 400 Bad Request if JSON parsing fails. *)
  | `POST, ["json"] -> Filter.body_json @@ hello
  (* Route to a 'nested' server, and also apply a filter to this scope *)
  | meth, "auth" :: path ->
    Filter.basic_auth @@ auth_server @@ (meth, path)
  (* Example of putting the service directly in the router, usually we
     avoid this because we'd like to keep the router small and readable. *)
  | `GET, ["redirect"] -> fun _ -> Response.of_redirect "/hello"
  | _ -> not_found

(* Apply a top-level filter to the entire server *)
let server dir ~sw route = reject_explorer @@ server dir ~sw @@ route

(* Run the server *)
let () =
  Eio_main.run @@ fun env ->
  main
    (Eio.Stdenv.net env)
    (Eio.Stdenv.domain_mgr env)
    (server @@ Eio.Stdenv.cwd env)
