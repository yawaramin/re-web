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

type ('ctx, 'resp) http_service =
  'ctx Request.t -> ([> Response.http] as 'resp) Lwt.t

type ('ctx, 'resp) t = route -> ('ctx, 'resp) service
(** A server is a function that takes a [route] and returns a service. A
    route is pattern-matchable (see above), so you will almost always do
    that to handle different endpoints with different services. *)

val resource :
  ?index:('ctx, 'resp) http_service ->
  ?create:('ctx, 'resp) http_service ->
  ?new_:('ctx, 'resp) http_service ->
  ?edit:(string -> ('ctx, 'resp) http_service) ->
  ?show:(string -> ('ctx, 'resp) http_service) ->
  ?update:([`PATCH | `PUT] -> string -> ('ctx, 'resp) http_service) ->
  ?destroy:(string -> ('ctx, 'resp) http_service) ->
  route ->
  ('ctx, 'resp) http_service
(** [resource ?index ?create ?new_ ?edit ?show ?update ?destroy]
    returns a resource, that is a server, with the standard HTTP
    CRUD actions that you specify as services. The resource handles
    the paths corresponding to those CRUD actions:

    - [GET /scope]: [index]
    - [POST /scope]: [create]
    - [GET /scope/new]: [new_]
    - [GET /scope/id/edit]: [edit id]
    - [GET /scope/id]: [show id]
    - [PATCH /scope/id]: [update `PATCH id]
    - [PUT /scope/id]: [update `PUT id]
    - [DELETE /scope/id]: [destroy id]

    The [scope] above is whatever scope you put the resource inside in a
    parent router, or maybe even the toplevel scope [/] if you use the
    resource directly as your toplevel server.

    All the service parameters are optional, with a 404 Not Found
    response as the default. *)

val serve :
  ?port:int ->
  (unit, [< Response.http | Response.websocket]) t ->
  unit
(** [serve ?port server] starts the top-level [server] listening on
    [port]. Top-level servers must have no context i.e. their context is
    [()]. *)

