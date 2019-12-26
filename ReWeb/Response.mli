(** For the response functions below, [status] defaults to [`OK] unless
    otherwise noted, and the [cookies] parameter is converted into
    response headers and merged with the [headers] parameter. There is
    therefore a chance of duplication which you will have to watch out
    for. *)

type cookies = (string * string) list
(** A cookie [Set-Cookie: id=1] is encoded as: [[("id", "1")]]. *)

type headers = (string * string) list
(** a header [X-Client-Id: 1] is encoded as: [[("x-client-id", "1")]]. *)

type status = Httpaf.Status.t
type t = { envelope : Httpaf.Response.t; body : Body.t }

val body : t -> Body.t

val cookies : t -> cookies

val header : string -> t -> string option
(** [header name request] gets the last value corresponding to the given
    header, if present. *)

val headers : string -> t -> string list
(** [headers name request] gets all the values corresponding to the
    given header. *)

val make : status:status -> headers:(string * string) list -> Body.t -> t

val of_binary :
  ?status:status ->
  ?content_type:string ->
  ?headers:headers ->
  ?cookies:cookies ->
  string ->
  t

val of_file :
  ?status:status ->
  ?content_type:string ->
  ?headers:headers ->
  ?cookies:cookies ->
  string ->
  t Lwt.t
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
  ?cookies:cookies ->
  string ->
  t

val of_json :
  ?status:status ->
  ?headers:headers ->
  ?cookies:cookies ->
  Ezjsonm.t ->
  t

val of_status :
  ?content_type:[`text | `html] ->
  ?headers:headers ->
  ?cookies:cookies ->
  ?message:string ->
  status ->
  t
(** [of_status ?content_type ?headers ?cookies ?message status] responds
    with a standard boilerplate response message based on the
    [content_type] and [status]. [content_type] defaults to [`text]. The
    boilerplate message can be overridden by [message] if present. *)

val of_text :
  ?status:status ->
  ?headers:headers ->
  ?cookies:cookies ->
  string ->
  t

val of_view :
  ?status:status ->
  ?content_type:string ->
  ?headers:headers ->
  ?cookies:cookies ->
  ((string -> unit) -> unit) ->
  t
(** [of_view ?status ?content_type ?headers ?cookies view] responds with
    a rendered body as per the [view] function. The [view] is a function
    that takes a 'printer' function ([string -> unit]) as a parameter
    and 'prints' (i.e. renders piecemeal) strings to it. These strings
    are pushed out as they are rendered.

    The difference from [of_html], [of_binary], and the other functions
    is that those hold the entire response in memory before sending it
    to the client, while [of_view] holds only each piece of the response
    as it is streamed out. *)

val status : t -> status

