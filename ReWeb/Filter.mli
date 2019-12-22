type ('ctx1, 'ctx2) t = 'ctx2 Server.service -> 'ctx1 Server.service
(** A filter transforms a service. It can change the request (usually by
    changing the request context) or the response (by actually running
    the service and then modifying its response).

    Filters can be composed using function composition. *)

val basic_auth : ('ctx1, < username : string; password : string; prev : 'ctx1 >) t
(** [basic_auth] decodes and stores the login credentials sent with the
    [Authorization] header or returns a 401 Unauthorized error if there
    is none. *)

val bearer_auth : ('ctx1, < bearer_token : string; prev : 'ctx1 >) t
(** [bearer_auth] stores the bearer token sent with the [Authorization]
    header or returns a 401 Unauthorized error if there is none. *)

val body_json : (unit, < body : Ezjsonm.t >) t
(** [body_json] is a filter that transforms a 'root' service (i.e. one
    with [unit] context) into a service with a context containing the
    request body, parsed as JSON. *)

val body_string : (unit, < body : string >) t
(** [body_string] is a filter that transforms a 'root' service into a
    service whose context contains the request body as a single string. *)
