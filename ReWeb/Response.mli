type status = Httpaf.Status.t
type t = {envelope : Httpaf.Response.t; body : Body.t}

val binary : ?status:status-> ?content_type:string -> string -> t
val html : ?status:status -> string -> t
val json : ?status:status -> Ezjsonm.t -> t
val make : status:status -> headers:Httpaf.Headers.t -> Body.t -> t
val text : ?status:status -> string -> t
