(** For the response functions below, [status] defaults to [`OK] unless
    otherwise noted, and the [cookies] parameter is converted into
    response headers and merged with the [headers] parameter. There is
    therefore a chance of duplication which you will have to watch out
    for. *)

type headers = (string * string) list
(** a header [X-Client-Id: 1] is represented as:
    [[("x-client-id", "1")]]. *)

type status = Httpaf.Status.t

type resp = { envelope : Httpaf.Response.t; body : Body.t }
type http = [`HTTP of resp]

type pull = unit -> string option Lwt.t
type push = string option -> unit
type handler = pull -> push -> unit Lwt.t
type websocket = [`WebSocket of Httpaf.Headers.t option * handler]

type 'resp t = [> http | websocket] as 'resp
(** Response type, can be an HTTP or a WebSocket response. Most of the
    functions below work solely with HTTP responses, this is enforced at
    the type level. *)

val add_header :
  ?replace:bool ->
  name:string ->
  value:string ->
  [< http] ->
  [> http]
(** [add_header ?replace ~name ~value response] returns a response with
    a header [name] with value [value] added to the original [response].
    If [response] already contains the header [name], then its value is
    replaced only if [replace] is [true], which is the default. *)

val add_headers : headers -> [< http] -> [> http]
(** [add_headers headers response] returns a response with the [headers]
    added to the end of the original [response]'s header list. *)

val add_headers_multi :
  (string * string list) list ->
  [< http] ->
  [> http]
(** [add_headers_multi headers_multi response] returns a response with
    [headers_multi] added to the end of the original [response]'s header
    list. *)

val body : [< http] -> Body.t

val cookies : [< http] -> Cookies.t

val header : string -> [< http] -> string option
(** [header name request] gets the last value corresponding to the given
    header, if present. *)

val headers : string -> [< http] -> string list
(** [headers name request] gets all the values corresponding to the
    given header. *)

val make :
  status:status ->
  headers:(string * string) list ->
  Body.t ->
  [> http]

val of_binary :
  ?status:status ->
  ?content_type:string ->
  ?headers:headers ->
  ?cookies:Cookies.t ->
  string ->
  [> http]

val of_file :
  ?status:status ->
  ?content_type:string ->
  ?headers:headers ->
  ?cookies:Cookies.t ->
  string ->
  [> http] Lwt.t
(** [of_file ?status ?content_type ?headers ?cookies file_name] responds
    with the contents of [file_name] which must be an absolute path in
    the filesystem, with HTTP response code [status] and content-type
    header [content_type].

    If the file is not found, responds with a 404 Not Found status and
    an appropriate message.

    Warning: this function maps the entire file into memory. Don't use
    it for files larger than memory. *)

val of_html :
  ?status:status ->
  ?headers:headers ->
  ?cookies:Cookies.t ->
  string ->
  [> http]

val of_json :
  ?status:status ->
  ?headers:headers ->
  ?cookies:Cookies.t ->
  Ezjsonm.t ->
  [> http]

val of_redirect :
  ?content_type:string ->
  ?body:string ->
  string ->
  [> http]
(** [of_redirect ?content_type ?body location] responds with an HTTP
    redirect response to the new [location], with an optional
    [content_type] (defaulting to [text/plain]) and [body] (defaulting
    to an empty body). *)

val of_status :
  ?content_type:[`text | `html] ->
  ?headers:headers ->
  ?cookies:Cookies.t ->
  ?message:string ->
  status ->
  [> http]
(** [of_status ?content_type ?headers ?cookies ?message status] responds
    with a standard boilerplate response message based on the
    [content_type] and [status]. [content_type] defaults to [`text]. The
    boilerplate message can be overridden by [message] if present. *)

val of_text :
  ?status:status ->
  ?headers:headers ->
  ?cookies:Cookies.t ->
  string ->
  [> http]

val of_view :
  ?status:status ->
  ?content_type:string ->
  ?headers:headers ->
  ?cookies:Cookies.t ->
  ((string -> unit) -> unit) ->
  [> http]
(** [of_view ?status ?content_type ?headers ?cookies view] responds with
    a rendered body as per the [view] function. The [view] is a function
    that takes a 'printer' function ([string -> unit]) as a parameter
    and 'prints' (i.e. renders piecemeal) strings to it. These strings
    are pushed out as they are rendered.

    The difference from [of_html], [of_binary], and the other functions
    is that those hold the entire response in memory before sending it
    to the client, while [of_view] holds only each piece of the response
    as it is streamed out. *)

val of_websocket : ?headers:headers -> handler -> [> websocket]
(** [of_websocket ?headers handler] responds with an open WebSocket.
    Optionally you can pass along extra [headers] which will be sent to
    the client when opening the WS.

    [handler pull push] is an asynchronous callback that manages the WS
    from the server side.

    [pull ()] asynchronously gets the next message from the WS if there
    is any.

    [push response] pushes the string [content] of [response] to the WS
    client if it is [Some content]; otherwise if it is [None] it closes
    the WS from the server side.

    {i Note} OCaml strings are un-encoded byte arrays, so it's up to you
    as the WebSocket handler writer to encode/decode them as necessary. *)

val status : [< http] -> status

