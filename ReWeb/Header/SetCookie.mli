(** See {{: https://developer.mozilla.org/en-US/docs/Web/HTTP/Cookies}}
    for explanations of all the options below. *)

type same_site = None | Strict | Lax
(** Cookie same-site policy. *)

type t
(** Set-Cookie header. *)

val name : t -> string
(** [name(cookie)] gets the cookie name. *)

val of_header : string -> t option
(** [of_header(header)] tries to parse the [header] string into a
    cookie. *)

val make :
  ?max_age:int ->
  ?secure:bool ->
  ?http_only:bool ->
  ?domain:string ->
  ?path:string ->
  ?same_site:same_site ->
  name:string ->
  string ->
  t
(** [make(?max_age, ?secure, ?http_only, ?domain, ?path, ?same_site, ~name, value)]
    creates a cookie with the given options.

    [secure] defaults to [true] but can be overridden here or at the
    config level.

    [same_site] defaults to [Lax]. *)

val to_header : t -> string * string
(** [to_header(cookie)] returns a [Set-Cookie] header setting the
    [cookie]. *)

val value : t -> string
(** [value(cookie)] gets the cookie value including all directives. *)

