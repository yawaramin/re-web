type status = Httpaf.Status.t
type t = { envelope : Httpaf.Response.t; body : Body.t }

val body : t -> Body.t

val header : string -> t -> string option
(** [header name request] gets the last value corresponding to the given
    header, if present. *)

val headers : string -> t -> string list
(** [headers name request] gets all the values corresponding to the
    given header. *)

val of_binary : ?status:status -> ?content_type:string -> string -> t
val of_html : ?status:status -> string -> t
val of_json : ?status:status -> Ezjsonm.t -> t
val make : status:status -> headers:(string * string) list -> Body.t -> t

val of_view :
  ?status:status ->
  ?content_type:string ->
  ((string -> unit) -> unit) ->
  t
(** [of_view ?status ?content_type view] responds with a rendered body
    as per the [view] function. The [view] is a function that
    takes a 'printer' function ([string -> unit]) as a parameter and
    'prints' (i.e. renders piecemeal) strings to it. These strings are
    pushed out as they are rendered.

    The difference from [of_html], [of_binary], and the other functions
    is that those hold the entire response in memory before sending it
    to the client, while [of_view] holds only each piece of the response
    as it is streamed out. *)

val of_file : ?status:status -> ?content_type:string -> string -> t Lwt.t
(** [of_file ?status ?content_type file_name] responds with the contents
    of [file_name] which must be an absolute path in the system, with
    HTTP response code [status] and content-type header [content_type]. *)

val of_text : ?status:status -> string -> t

val status : t -> status

