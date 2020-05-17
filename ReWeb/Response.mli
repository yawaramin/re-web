(** For the response functions below, [status] defaults to [`OK] unless
    otherwise noted, and the [cookies] parameter is converted into
    response headers and merged with the [headers] parameter. There is
    therefore a chance of duplication which you will have to watch out
    for. *)

module Header = ReWeb__Header

type headers = (string * string) list
(** a header [X-Client-Id: 1] is represented as:
    [[("x-client-id", "1")]]. *)

type status = Httpaf.Status.t
(** See {{: https://b0-system.github.io/odig/doc@odoc.default/httpaf/Httpaf/Status/index.html} Httpaf.Status}
    for valid statuses. *)

type http = [`HTTP of Httpaf.Response.t * Body.t]

type pull_error = [
| `Empty
  (** The incoming message stream is empty. *)
| `Timeout
  (** Could not get a message from the stream within the given timeout. *)
| `Connection_close
  (** Connection was closed by the client. {b Warning:} you must exit
      the WebSocket handler as soon as possible when this happens.
      Otherwise, you will be in an infinite loop waiting for messages
      that will never arrive. *)
]
(** Possible issues with pulling a message from the incoming messages
    stream. *)

type pull = float -> (string, pull_error) result Lwt.t
(** [pull(timeout_s)] asynchronously gets the next message from the
    WebSocket if there is any, with a timeout in seconds of [timeout_s].
    If it doesn't time out it returns [Some string], otherwise [None]. *)

type push = string -> unit
(** [push(response)] pushes the string [response] to the WebSocket
    client. *)

type handler = pull -> push -> unit Lwt.t
(** [handler(pull, push)] is an asynchronous callback that manages the
    WS from the server side. The WS will shut down from the server side
    as soon as [handler] exits, so if you want to keep it open you need
    to make it call itself recursively. Because the call will be
    tail-recursive, OCaml's tail-call elimination takes care of stack
    memory use. *)

type websocket = [`WebSocket of Httpaf.Headers.t option * handler]
(** A WebSocket response. *)

type 'resp t = [> http | websocket] as 'resp
(** Response type, can be an HTTP or a WebSocket response. Many of the
    functions below work with either HTTP or WebSocket responses, and
    some with only one or the other. This is enforced at the type level. *)

val add_cookie :
  Header.SetCookie.t ->
  [< http | websocket] ->
  _ t
(** [add_cookie(cookie, response)] returns a response with a cookie
    [cookie] added to the original [response]. *)

val add_cookies :
  Header.SetCookie.t list ->
  [< http | websocket] ->
  _ t
(** [add_cookies(cookies, response)] returns a response with the
    [cookies] added to the original [response]. *)

val add_header :
  ?replace:bool ->
  name:string ->
  value:string ->
  [< http | websocket] ->
  _ t
(** [add_header(?replace, ~name, ~value, response)] returns a response
    with a header [name] with value [value] added to the original
    [response]. If the response already contains the [header], then it
    is replaced only if [replace] is [true], which is the default. *)

val add_headers : headers -> [< http | websocket] -> _ t
(** [add_headers(headers, response)] returns a response with the
    [headers] added to the end of the original [response]'s header list. *)

val add_headers_multi :
  (string * string list) list ->
  [< http | websocket] ->
  _ t
(** [add_headers_multi(headers_multi, response)] returns a response with
    [headers_multi] added to the end of the original [response]'s header
    list. *)

val body : [< http] -> Body.t

val cookies : [< http | websocket] -> Header.SetCookie.t list

val header : string -> [< http | websocket] -> string option
(** [header(name, request)] gets the last value corresponding to the
    given header, if present. *)

val headers : string -> [< http | websocket] -> string list
(** [headers(name, request)] gets all the values corresponding to the
    given header. *)

val of_binary :
  ?status:status ->
  ?content_type:string ->
  ?headers:headers ->
  ?cookies:Header.SetCookie.t list ->
  string ->
  [> http]

val of_file :
  ?status:status ->
  ?content_type:string ->
  ?headers:headers ->
  ?cookies:Header.SetCookie.t list ->
  string ->
  [> http] Lwt.t
(** [of_file(?status, ?content_type, ?headers, ?cookies, file_name)]
    responds with the contents of [file_name], which is a relative or
    absolute path, with HTTP response code [status] and content-type
    header [content_type].

    If the file is not found, responds with a 404 Not Found status and
    an appropriate message.

    {i Warning} this function maps the entire file into memory. Don't
    use it for files larger than memory. *)

val of_html :
  ?status:status ->
  ?headers:headers ->
  ?cookies:Header.SetCookie.t list ->
  string ->
  [> http]

val of_http :
  status:status ->
  headers:(string * string) list ->
  Body.t ->
  [> http]
(** [of_http(~status, ~headers, body)] responds with an HTTP response
    composed of [status], [headers], and [body]. *)

val of_json :
  ?status:status ->
  ?headers:headers ->
  ?cookies:Header.SetCookie.t list ->
  Yojson.Safe.t ->
  [> http]

val of_redirect :
  ?content_type:string ->
  ?body:string ->
  string ->
  [> http]
(** [of_redirect(?content_type, ?body, location)] responds with an HTTP
    redirect response to the new [location], with an optional
    [content_type] (defaulting to [text/plain]) and [body] (defaulting
    to an empty body). *)

val of_status :
  ?content_type:[`text | `html] ->
  ?headers:headers ->
  ?cookies:Header.SetCookie.t list ->
  ?message:string ->
  status ->
  [> http]
(** [of_status(?content_type, ?headers, ?cookies, ?message, status)]
    responds with a standard boilerplate response message based on the
    [content_type] and [status]. [content_type] defaults to [`text]. The
    boilerplate message can be overridden by [message] if present. *)

val of_text :
  ?status:status ->
  ?headers:headers ->
  ?cookies:Header.SetCookie.t list ->
  string ->
  [> http]

val of_view :
  ?status:status ->
  ?content_type:string ->
  ?headers:headers ->
  ?cookies:Header.SetCookie.t list ->
  ((string -> unit) -> unit) ->
  [> http]
(** [of_view(?status, ?content_type, ?headers, ?cookies, view)] responds
    with a rendered body as per the [view] function. The [view] is a
    function that takes a 'printer' function ([string -> unit]) as a
    parameter and 'prints' (i.e. renders piecemeal) strings to it. These
    strings are pushed out as they are rendered.

    The difference from [of_html], [of_binary], and the other functions
    is that those hold the entire response in memory before sending it
    to the client, while [of_view] holds only each piece of the response
    as it is streamed out. *)

val of_websocket : ?headers:headers -> handler -> [> websocket]
(** [of_websocket(?headers, handler)] is an open WebSocket response.
    Optionally you can pass along extra [headers] which will be sent to
    the client when opening the WS.

    {i Warning} it can be a little tricky to write a completely
    asynchronous WebSocket handler correctly. Be sure to read the
    reference documentation above, and the manual, carefully.

    {i Note} OCaml strings are un-encoded byte arrays, and ReWeb treats
    all incoming and outgoing WebSocket data as such--even if the client
    is sending UTF-8 encoded text format (see
    {{: https://developer.mozilla.org/en-US/docs/Web/API/WebSockets_API/Writing_WebSocket_servers#Format}}).
    It's up to you as the WebSocket handler writer to encode/decode them
    as necessary. *)

val status : [< http] -> status
val status_code : [< http] -> int

