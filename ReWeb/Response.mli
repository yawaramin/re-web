type t = {envelope : Httpaf.Response.t; body : Body.t}

val binary :
  ?status:Httpaf.Status.t ->
  ?content_type:string ->
  string ->
  t

val html : ?status:Httpaf.Status.t -> string -> t
val json : ?status:Httpaf.Status.t -> Ezjsonm.t -> t

val make :
  status:Httpaf.Status.t ->
  headers:Httpaf.Headers.t ->
  Body.t ->
  t

val text : ?status:Httpaf.Status.t -> string -> t
