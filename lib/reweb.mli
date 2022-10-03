module Form = Form
module Response = Response
module Request : Request.S
module Service : Service.S with type 'ctx Request.t = 'ctx Request.t

module Filter : Filter.S
  with type 'ctx Service.Request.t = 'ctx Request.t
  and type 'ctx Service.t = 'ctx Service.t

type path = string list
type route = Httpaf.Method.t * path
type 'ctx server = sw:Eio.Switch.t -> route -> 'ctx Service.t

val resource :
  ?index:'ctx Service.t ->
  ?create:'ctx Service.t ->
  ?new_:'ctx Service.t ->
  ?edit:(string -> 'ctx Service.t) ->
  ?show:(string -> 'ctx Service.t) ->
  ?update:([`PATCH | `PUT] -> string -> 'ctx Service.t) ->
  ?destroy:(string -> 'ctx Service.t) ->
  route ->
  'ctx Service.t
(** [resource ?index ?create ?new_ ?edit ?show ?update ?destroy] returns a
    resource--that is a server--with the standard HTTP CRUD actions that you
    specify as services. The resource handles the paths and sets a reasonable
    cache policy corresponding to those CRUD actions:

    - [GET /scope] or [GET /scope/] calls [index]
    - [POST /scope] calls [create] and disables caching
    - [GET /scope/new] or [GET /scope/new/] calls [new_] and sets the response to
      cache publicly for a week
    - [GET /scope/id/edit] or [GET /scope/id/edit/] calls [edit id]
    - [GET /scope/id] or [GET /scope/id/] calls [show id]
    - [PATCH /scope/id] calls [update `PATCH id] and disables caching
    - [PUT /scope/id] calls [update `PUT id] and disables caching
    - [DELETE /scope/id] calls [destroy id] and disables caching

    The [scope] above is whatever scope you put the resource inside in a parent
    router, or maybe even the toplevel scope [/] if you use the resource directly
    as your toplevel server.

    All the service parameters are optional, with a 404 Not Found response as the
    default. Note that [resource] is just a convenience function; you can
    implement a custom resource yourself if needed, by creating a server function
    of type ['ctx t] instead. *)

val main : #Eio.Net.t -> #Eio.Domain_manager.t -> unit server -> unit
(** [main net domain_mgr server] runs the server with the given capabilities. *)
