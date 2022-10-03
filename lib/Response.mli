(** For the response functions below, [status] defaults to [`OK] unless
    otherwise noted, and the [cookies] parameter is converted into
    response headers and merged with the [headers] parameter. There is
    therefore a chance of duplication which you will have to watch out
    for. *)

module Header = Reweb_header

type headers = (string * string) list
(** a header [X-Client-Id: 1] is represented as:
    [[("x-client-id", "1")]]. *)

type status = Httpaf.Status.t
(** See {{: https://b0-system.github.io/odig/doc@odoc.default/httpaf/Httpaf/Status/index.html} Httpaf.Status}
    for valid statuses. *)

type t = Httpaf.Response.t * Eio.Flow.source

val add_cookie : Header.SetCookie.t -> t -> t
(** [add_cookie cookie response] returns a response with a cookie
    [cookie] added to the original [response]. *)

val add_cookies : Header.SetCookie.t list -> t -> t
(** [add_cookies cookies response] returns a response with the
    [cookies] added to the original [response]. *)

val add_header : ?replace:bool -> name:string -> value:string -> t -> t
(** [add_header ?replace ~name ~value response] returns a response
    with a header [name] with value [value] added to the original
    [response]. If the response already contains the [header], then it
    is replaced only if [replace] is [true], which is the default. *)

val add_headers : headers -> t -> t
(** [add_headers headers response] returns a response with the
    [headers] added to the end of the original [response]'s header list. *)

val add_headers_multi : (string * string list) list -> t -> t
(** [add_headers_multi headers_multi response] returns a response with
    [headers_multi] added to the end of the original [response]'s header
    list. *)

val body : t -> Eio.Flow.source

val cookies : t -> Header.SetCookie.t list

val header : string -> t -> string option
(** [header(name, request)] gets the last value corresponding to the
    given header, if present. *)

val headers : string -> t -> string list
(** [headers(name, request)] gets all the values corresponding to the
    given header. *)

val of_binary :
  ?status:status ->
  ?content_type:string ->
  ?headers:headers ->
  ?cookies:Header.SetCookie.t list ->
  string ->
  t

val of_file :
  ?status:status ->
  ?content_type:string ->
  ?headers:headers ->
  ?cookies:Header.SetCookie.t list ->
  sw:Eio.Switch.t ->
  _ Eio.Path.t ->
  string ->
  t
(** [of_file ?status ?content_type ?headers ?cookies ~sw path filename] responds
    with the contents of [filename], which is relative to [path], with HTTP
    response code [status] and content-type header [content_type].

    Uses [sw] to automatically close the file once the response fiber is done.

    If the file is not found, responds with a 404 Not Found status and an
    appropriate message. *)

val of_html :
  ?status:status ->
  ?headers:headers ->
  ?cookies:Header.SetCookie.t list ->
  string ->
  t

val of_flow :
  status:status ->
  headers:(string * string) list ->
  Eio.Flow.source ->
  t
(** [of_http ~status, ~headers body] responds with an HTTP response composed of
    [status], [headers], and [body]. *)

val of_json :
  ?status:status ->
  ?headers:headers ->
  ?cookies:Header.SetCookie.t list ->
  Yojson.Safe.t ->
  t

val of_redirect :
  ?content_type:string ->
  ?body:string ->
  string ->
  t
(** [of_redirect ?content_type ?body location] responds with an HTTP redirect
    response to the new [location], with an optional [content_type] (defaulting
    to [text/plain]) and [body] (defaulting to an empty body). *)

val of_status :
  ?content_type:[`text | `html] ->
  ?headers:headers ->
  ?cookies:Header.SetCookie.t list ->
  ?message:string ->
  status ->
  t
(** [of_status ?content_type ?headers ?cookies ?message status)] responds with a
    standard boilerplate response message based on the [content_type] and [status].
    [content_type] defaults to [`text]. The boilerplate message can be overridden
    by [message] if present. *)

val of_text :
  ?status:status ->
  ?headers:headers ->
  ?cookies:Header.SetCookie.t list ->
  string ->
  t

val status : t -> status
val status_code : t -> int
