type ('ctx1, 'ctx2) t = 'ctx2 Server.service -> 'ctx1 Server.service
(** A filter transforms a service, possibly changing its context type.
    Filters are just functions, so they can be composed using function
    composition. Because of this design, the ['ctx2 service] actually
    represents the {i next} service in the pipeline after the current
    filter runs. This is a lot like Express middleware functions that
    take a 'next' middleware as an argument. *)

val basic_auth : ('ctx1, < username : string; password : string; prev : 'ctx1 >) t

val bearer_auth : ('ctx1, < bearer_token : string; prev : 'ctx1 >) t

val body_json : (unit, < body : Ezjsonm.t >) t
(** [body_json] is a filter that transforms a 'root' service (i.e. one
    with [unit] context) into a service with a context containing the
    request body, parsed as JSON. *)

val body_string : (unit, < body : string >) t
(** [body_string] is a filter that transforms a 'root' service into a
    service whose context contains the request body as a single string. *)
