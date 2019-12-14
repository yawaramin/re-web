type 'ctx t = {ctx : 'ctx; reqd : Httpaf.Reqd.t}

val body : unit t -> Bigstringaf.t Lwt_stream.t t

val context : 'ctx t -> 'ctx

val header : string -> _ t -> string option
(** [header name request] gets the last value corresponding to the given
    header, if present. *)

val headers : string -> _ t -> string list
(** [headers name request] gets all the values corresponding to the given
    header. *)

val make : Httpaf.Reqd.t -> unit t
