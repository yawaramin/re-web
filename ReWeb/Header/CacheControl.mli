(** See
    {{: https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Cache-Control}}
    for detailed explanations of the various cache options. *)

type privately = {
  must_revalidate : bool option;
  max_age : int option; (** In seconds *)
}
(** Caching options for the end user's device. *)

type publicly = {
  no_transform : bool option;
  proxy_revalidate : bool option;
  s_maxage : int option; (** In seconds *)
}
(** Caching options for proxies and other devices than the end user. *)

type t =
| No_store (** Don't cache at all *)
| No_cache (** Cache but revalidate with every request *)
| Private of privately (** Cache on end user's device only *)
| Public of privately * publicly (** Cache anywhere *)
(** Possible values of the [Cache-Control] response header. *)

val private_ : ?must_revalidate:bool -> ?max_age:int -> unit -> t
(** [private_(?must_revalidate, ?max_age, ())] is a convenience function
    for creating a private cache response. *)

val public :
  ?must_revalidate:bool ->
  ?max_age:int ->
  ?no_transform:bool ->
  ?proxy_revalidate:bool ->
  ?s_maxage:int ->
  unit ->
  t
(** [public(?must_revalidate, ?max_age, ?no_transform, ?proxy_revalidate, ?s_maxage, ())]
    is a convenience function for creating a public cache response. *)

val to_string : t -> string
(** [to_string(value)] converts the cache-control instructions into a
    comma-separated list of directives. *)

