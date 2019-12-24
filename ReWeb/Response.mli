(** For the response functions below, [status] defaults to [`OK] unless
    otherwise noted. *)

type status = Httpaf.Status.t
type t = {envelope : Httpaf.Response.t; body : Body.t}

val binary : ?status:status -> ?content_type:string -> string -> t
(** [binary ?status ?content_type body] sends a binary (string) response
    body. [content_type] defaults to [application/octet-stream]. *)

val html : ?status:status -> string -> t
val json : ?status:status -> Ezjsonm.t -> t
val make : status:status -> headers:Httpaf.Headers.t -> Body.t -> t

val render :
  ?status:status ->
  ?content_type:string ->
  ((string -> unit) -> unit) ->
  t
(** [render ?status ?content_type view] responds with a rendered body
    as per the [view] function. [view] is a function that takes a
    'printer' function ([string -> unit]) as a parameter and
    'prints' (i.e. renders piecemeal) strings to it. These strings are
    pushed out as they are rendered.

    The difference from [html], [binary], and the other functions is that
    those hold the entire response in memory before sending it to the
    client, while [render] holds only each piece of the response as it is
    streamed out.

    [content_type] defaults to [text/html]. *)

val static : ?status:status -> ?content_type:string -> string -> t Lwt.t
(** [static ?status ?content_type file_name] responds with the contents
    of [file_name] which must be an absolute path in the system, with
    HTTP response code [status] and content-type header [content_type]. *)

val text : ?status:status -> string -> t
