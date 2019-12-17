type ('ctx, 'fd, 'io) t = {ctx : 'ctx; reqd : ('fd, 'io) Httpaf.Reqd.t}

val context : ('ctx, _, _) t -> 'ctx

val header : string -> (_, _, _) t -> string option
(** [header name request] gets the last value corresponding to the given
    header, if present. *)

val headers : string -> (_, _, _) t -> string list
(** [headers name request] gets all the values corresponding to the given
    header. *)

val make : ('fd, 'io) Httpaf.Reqd.t -> (unit, 'fd, 'io) t

val with_body : (unit, 'fd, 'io) t -> (Body.t, 'fd, 'io) t
