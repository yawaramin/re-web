type path = string list

type route = Httpaf.Method.t * path
(** Pattern-matchable identifier of the request for routing purposes.
    Consists of:

    - HTTP method e.g. [`GET], [`POST]
    - [path] i.e. a list of path segments

    E.g., [GET /api/user/1] would be represented as
    [(`GET, ["api", "user", "1"])] *)

type ('ctx, 'resp) service = 'ctx Request.t -> 'resp Response.t Lwt.t
(** A service is an asynchronous function that handles a request and
    returns a response. See also {!module:Filter} for filters which can
    manipulate services. *)

type ('ctx, 'resp) t = route -> ('ctx, 'resp) service
(** A server is a function that takes a [route] and returns a service. A
    route is pattern-matchable (see above), so you will almost always do
    that to handle different endpoints with different services. *)

val serve :
  ?port:int ->
  (unit, [< Response.http | Response.websocket]) t ->
  unit Lwt.t
(** [serve ?port server] starts the top-level [server] listening on
    [port]. Top-level servers must have no context i.e. their context is
    [()]. *)

