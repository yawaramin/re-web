type t = {envelope : Httpaf.Response.t; body : Bigstringaf.t Lwt_stream.t}

val html : ?status:Httpaf.Status.t -> string -> t

val json : ?status:Httpaf.Status.t -> Ezjsonm.t -> t

val make :
  status:Httpaf.Status.t ->
  headers:Httpaf.Headers.t ->
  Bigstringaf.t Lwt_stream.t ->
  t

val text :
  ?status:Httpaf.Status.t ->
  ?content_type:string ->
  string ->
  t

(*
type headers = (string * string) list
(** Key-value pair. Used for both headers and cookies. For cookies, you
    can add directives to the value in the same way as shown in the
    {{: https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Set-Cookie} Set-Cookie}
    header documentation. E.g., [("userid", "abc123; Max-Age=86400")]. *)

type t = {
  assigns: Ezjsonm.t;
  body: Bigstringaf.t Lwt_stream.t;
  cookies: headers;
  headers: headers;
  status: Httpaf.Status.t;
}
(** Models the response status, headers (including cookies), and body. *)

val empty : t

val html : string -> t -> t
(** [html string response] sends an HTML response [string] with status
    200. *)

val json : Ezjsonm.t -> t -> t
(** [json value response] sends a JSON response [value] with status 200. *)

val not_found : ?template:string -> t -> t
(** [not_found ?template response] sets a [response] status of
    [`Not_found] (404) along with a body read from the given [template]
    file. The default template is [not-found.mustache.html]. *)

val render :
  ?status:Httpaf.Status.t ->
  ?assigns:Ezjsonm.t ->
  template:string ->
  t ->
  t
(** [render ?status ?assigns ~template response] sets the [response] body
    using the given [template] (file name) and the [assigns] needed by
    the template. Caller is responsible for passing in the correct
    assigns. Assigns must be a JSON object formatted as shown in
    {{: https://github.com/rgrinberg/ocaml-mustache} the Mustache README}.
    Also sets the [status] and the [content-type] header for HTML and
    JSON files. Template files must be in the [template] subdirectory. *)

val set :
  ?status:Httpaf.Status.t ->
  ?body:Lwt_io.input_channel ->
  ?assigns:Ezjsonm.t ->
  ?headers:headers ->
  ?cookies:headers ->
  t ->
  t
(** [set ?status ?body ?assigns ?headers ?cookies response] sets
    [response] properties. Note that [headers], [cookies], and [assigns]
    are set in an additive way because we don't want to lose any that
    others may have set earlier. Set all headers in lowercase to avoid
    redundant headers.

    [assigns] is a JSON object with possibly any contents but usually the
    ones needed to render a template (see [render]). *)

val text : string -> t -> t
(** [text string response] sends a plain text response [string] with
    status 200. *)
*)
