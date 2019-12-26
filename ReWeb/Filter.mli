(** The filters here that don't read the request body additionally
    preserve whatever context was already in the request before the
    current filter ran. They do this by putting the previous context in
    a [prev] method in the new context object. This is just a convention
    but a useful one.

    The filters which read the body don't do this because they only work
    with request which have no context (i.e., context of type [unit]). *)

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
    request body. If the request body fails to parse as valid JSON, it
    short-circuits and returns a 400 Bad Request. *)

val body_string : (unit, < body : string >) t
(** [body_string] is a filter that transforms a 'root' service into a
    service whose context contains the request body as a single string. *)

val body_form : ('ctor, 'ty) Form.t -> (unit, < form : 'ty >) t
(** [body_form typ] is a filter that decodes a web form in the request
    body and puts it inside the request for the next service. The
    decoding is done as specified by the form definition [typ]. If the
    form fails to decode, it short-circuits and returns a 400 Bad
    Request. *)

val query_form : ('ctor, 'ty) Form.t -> ('ctx1, < query : 'ty; prev : 'ctx1 >) t
(** [query_form typ] is a filter that decodes the request query (the
    part after the [?] in the endpoint) into a value of type ['ty] and
    stores it in the request context for the next service. The decoding
    and failure works in the same way as for [body_form]. *)

