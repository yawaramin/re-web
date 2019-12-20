type 'ctx t = {
  ctx : 'ctx;
  reqd : (Lwt_unix.file_descr, unit Lwt.t) Httpaf.Reqd.t;
}

val body : unit t -> Body.t

val body_string : ?buf_size:int -> unit t -> string Lwt.t
(** [body_string ?buf_size request] returns the request body converted
    into a string, internally using a buffer of size [buf_size] with a
    default of Lwt's default buffer size. *)

val context : 'ctx t -> 'ctx

val header : string -> _ t -> string option
(** [header name request] gets the last value corresponding to the given
    header, if present. *)

val headers : string -> _ t -> string list
(** [headers name request] gets all the values corresponding to the given
    header. *)

val make : (Lwt_unix.file_descr, unit Lwt.t) Httpaf.Reqd.t -> unit t
