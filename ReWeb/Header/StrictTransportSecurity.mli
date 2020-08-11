(** Convenience to create the
    {{: https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Strict-Transport-Security} HSTS}
    header. *)

type t = private {
  max_age : int; (** In seconds *)
  include_subdomains : bool;
  preload : bool;
}

val make : ?include_subdomains:bool -> ?preload:bool -> int -> t
(** [make(?include_subdomains, ?preload, max_age)] represents an HSTS
    header with the given options. *)

val to_header : t -> string * string

