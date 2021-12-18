(* This is an example that shows the various features of ReWeb for
   creating web servers. You can skip to the bottom of the file to see
   the router, and work your way back up if you want. *)

(* [ReWeb] contains just a handful of modules so there's very little
   chance of a conflict. *)
open ReWeb

(** [not_found request] is a service that responds with a formatted HTML
    404 Not Found message. *)
let not_found  _ =
  {|<!doctype html>
<html>
  <head>
    <meta charset="utf-8">
    <title>Not Found</title>
  </head>
  <body>
    <h1>Not Found</h1>
  </body>
</html>|}
  |> Response.of_html ~status:`Not_found
  |> Lwt.return

(** [hello request] is a service that just responds with a hello-world message. *)
let hello _ = "Hello, World!" |> Response.of_text |> Lwt.return

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
    |> Lwt.return
  | None ->
    not_found request

(** [get_login request] is a service that renders a view. Open the file [view.ml]
    to see what the [login] view looks like. *)
let get_login _ = View.login ~remember_me:true |> Response.of_view |> Lwt.return

(** [post_login request] is a service that handles the [POST /login] endpoint.
    It's statically guaranteed access to the request body as a decoded, strongly-
    typed form, because a form decoder filter was added before the service in the
    router.

    It returns the credentials in the response body. *)
let post_login request =
  let { User.username; password } = Request.context request in
  View.logged_in ~username ~password |> Response.of_view |> Lwt.return

(** [getLoginQuery(request)] is a service that handles the [GET /login-query]
    endpoint. It's statically guaranteed access to the decoded, strongly-typed
    request query, because a query decoder filter was added before the service in
    the router. *)
let get_login_query request =
  let { User.username; password } = (Request.context request)#query in
  View.logged_in ~username ~password |> Response.of_view |> Lwt.return

(** [get_static filename request] is a service that returns the contents of
    [filename] (if found). Note that [filename] {i must} be an absolute path. *)
let get_static filename _ =
  filename |> String.concat "/" |> (( ^ ) "/") |> Response.of_file

(** [echo_body request] is a service that directly echoes the [request] body back
    to the client, without touching it at all. *)
let echo_body request = request
  |> Request.body
  |> Response.of_http
    ~status:`OK
    ~headers:[
      "content-type", "application/octet-stream";
      "connection", "close";
    ]
  |> Lwt.return

(** [exclaim_body request] is a service that echoes the [request] body but with
    an exclamation mark added to the end. *)
let exclaim_body request = request
  |> Request.body_string
  |> Lwt.map @@ fun string -> Response.of_text (string ^ "!")

(* Helper function (not a service as it doesn't take a request) *)
let internal_server_error message =
  `Internal_server_error |> Response.of_status ~message |> Lwt.return

(** [get_todo id request] gets the todo item with ID [id] from the JSON
    Placeholder API and returns the response {i exactly,} including all headers
    from the source. You can test this by running the command:
    [curl -i localhost:8080/todos/1] and checking the headers. *)
let get_todo id _ =
  let open Lwt.Syntax in
  let* response =
    Client.New.get ("https://jsonplaceholder.typicode.com/todos/" ^ id)
  in
  match response with
  | Ok response -> Lwt.return response
  | Error string -> internal_server_error string

(** [get_todo_title id request] gets the todo item with ID [id] from the JSON
    Placeholder API, and extracts and returns only the title of the todo item. *)
let get_todo_title id request =
  let open Lwt.Syntax in
  let* response = get_todo id request in
  let* result = response |> Response.body |> Piaf.Body.to_string in
  match result with
  | Ok string ->
    (* We are manually pattern-matching against the JSON body here. You can also
       use [ppx_deriving_yojson] to auto-derive JSON decoders for your types. *)
    begin match Yojson.Safe.from_string string with
    | `Assoc props ->
      begin match List.assoc "title" props with
      | `String title ->
        title |> Response.of_text |> Lwt.return
      | _
      | exception Not_found ->
        internal_server_error "get_todo_title: malformed JSON response"
      end
    | _
    | exception _ ->
      internal_server_error "get_todo_title: malformed JSON response"
    end
  | Error _ ->
    internal_server_error "getTodo: error reading upstream response body"

(** [authHello(request)] is a service that handles [GET /auth/hello].
    It's statically guaranteed to access the credentials in the request
    context (because the filter was applied in the top-level server). *)
let auth_hello request =
  let context = Request.context request in
  context#password
  |> Printf.sprintf "Username = %s\nPassword = %s" context#username
  |> Response.of_text
  |> Lwt.return

(** [get_echo_ws request] is a service that handles a WebSocket connection. It
    just echoes any strings that the client sends, unless the string is [close],
    in which case it closes the connection. *)
let get_echo_ws _ =
  (* Set up a handler function, with the ability to pass in some state *)
  let rec handler ?(greet=false) pull push =
    if greet then push "Welcome to get_echo_ws!\n";
    let open Lwt.Syntax in
    (* Use the provided [pull] function to asynchronously get a message.
       Note that this is under your control, you decide when to get the
       next message. Have to pass in an explicit timeout in seconds to
       all pulls. *)
    let* message = pull 2. in
    let message = Stdlib.Result.map String.trim message in
    match Result.map String.trim message with
    | Ok "close"
    | Error `Connection_close ->
      (* Close the connection by just returning a 'unit' promise. This
         is a convenience value that's like saying [Promise.resolve()]
         (i.e. resolve with an empty value) in JavaScript. *)
      Lwt_io.printf "Connection closed by client!\n"
    | Ok string ->
      (* Echo the message back by pushing it *)
      push string;

      (* Call self recursively. This is needed to keep the handler
         running--otherwise it will exit and close the WS connection.
         If you've ever seen how an Erlang actor works, this is the
         same idea. *)
      handler pull push
    (* If we didn't get a message, keep running *)
    | _ ->
      handler pull push
  in
  (* Make and return a response like usual, but this time instead of
     HTTP info (status, headers, body) return the WS handler. Note that
     a handler can be passed in some extra state ([~greet:true]) at the
     beginning, and update the state internally when it calls itself
     recursively! *)
  handler ~greet:true |> Response.of_websocket |> Lwt.return

(* Server for /auth/... endpoints, enforcing basic auth (see below) *)
let auth_server = function
  | `GET, ["hello"] -> auth_hello
  | _ -> not_found

let msie = Str.regexp ".*MSIE.*"

(* Filter that rejects requests from MSIE *)
let reject_explorer next request = match Request.header "user-agent" request with
  | Some ua when Str.string_match msie ua 0 ->
    `Unauthorized
    |> Response.of_status ~message:"Please upgrade your browser"
    |> Lwt.return
  | _ ->
    next request

(* The top-level server (which is also a router simply by using pattern-
   matching syntax). In the filter examples below which use [@@] you can
   think of it as 'and' or 'then', i.e. 'first apply this filter then
   send the request to the service'. Actually [@@] is a generic operator
   provided by the standard library: [f x @@ y == f x y]. *)
let server = function
  | `GET, ["hello"] -> hello
  | `GET, ["header"; name] -> get_header name
  | `GET, ["login"] -> get_login
  (* Applies a filter to the [POST /login] endoint to decode a form in
     the request body to a strongly-typed value. Returns 400 Bad Request
     if form decoding fails. Open the file [User.re] to see how the form
     is defined. *)
  | `POST, ["login"] -> Filter.body_form User.form @@ post_login
  (* Applies a filter to the [GET /login-query] endpoint to decode the
     request query to the same form as above. For demo purposes only,
     obviously we won't be sending login credentials in the query in
     real code :-) *)
  | `GET, ["login-query"] -> Filter.query_form User.form @@ get_login_query
  | `GET, "static" :: filename -> get_static filename
  | `POST, ["body"] -> echo_body
  | `POST, ["body-bang"] -> exclaim_body
  (* Applies a filter to the [POST /json] endpoint to parse the request
     body as JSON. Returns 400 Bad Request if JSON parsing fails. *)
  | `POST, ["json"] -> Filter.body_json @@ hello
  | `GET, ["todos"; id] -> get_todo id
  | `GET, ["todos"; "titles"; id] -> get_todo_title id
  (* Route to a 'nested' server, and also apply a filter to this scope *)
  | meth, "auth" :: path ->
    Filter.basic_auth @@ auth_server @@ (meth, path)
  (* Example of putting the service directly in the router, usually we
     avoid this because we'd like to keep the router small and readable. *)
  | `GET, ["redirect"] -> fun _ -> "/hello" |> Response.of_redirect |> Lwt.return
  (* Example of serving a WebSocket *)
  | `GET, ["ws"] -> get_echo_ws
  (* This is a really cool WS: it queries the {i same} ReWeb server it's
     running in to get data! *)
  | `GET, ["ticks"] -> Get_ticks.service
  (* Example of a Rails-like resource. Go to
     [http://localhost:8080/articles] in your browser to try it! *)
  | meth, "articles" :: path -> Articles.resource @@ (meth, path)
  | _ -> not_found

(* Apply a top-level filter to the entire server *)
let server route = reject_explorer @@ server @@ route

(* Run the server *)
let () = Server.serve server
