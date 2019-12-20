type path = string list

type route = Httpaf.Method.t * path
(** Pattern-matchable identifier of the request for routing purposes.
    Consists of:

    - HTTP method e.g. [`GET] and [`POST]
    - (String) list of path segments

    E.g., [GET /api/user/1] would be represented as
    [(`GET, ["api", "user", "1"])] *)

type 'ctx service = 'ctx Request.t -> Response.t Lwt.t
type 'ctx t = route -> 'ctx service

val scope : route -> 'ctx t -> 'ctx service

val serve : ?port:int -> unit t -> unit Lwt.t
(** [serve ?port server] starts the top-level [server] listening on
    [port]. Top-level servers must have no context i.e. their context is
    [()]. *)
