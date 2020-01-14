(** See {{: https://developer.mozilla.org/en-US/docs/Web/HTTP/Cookies}}
    for explanations of all the options below. *)

type same_site = None | Strict | Lax
type t

val name : t -> string

val of_header : string -> t option

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

val to_header : t -> string * string
(** [to_header(cookie)] returns a [Set-Cookie] header setting the
    [cookie]. *)

val value : t -> string

