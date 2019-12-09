type 'ctx t

val body : 'ctx t -> Bigstringaf.t Lwt_stream.t
(** [body request] returns the body of the [request]. *)

val ctx : 'ctx t -> 'ctx
val header : string -> t -> string option
val headers : string -> t -> string list

val make : Httpaf.Reqd.t -> unit t
