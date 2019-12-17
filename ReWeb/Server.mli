type path = string list

type route = Httpaf.Method.t * path
(** Pattern-matchable identifier of the request for routing purposes.
    Consists of:

    - HTTP method e.g. [`GET] and [`POST]
    - (String) list of path segments

    E.g., [GET /api/user/1] would be represented as
    [(`GET, ["api", "user", "1"])] *)

type ('ctx, 'fd, 'io) service = ('ctx, 'fd, 'io) Request.t -> Response.t Lwt.t
type ('ctx1, 'ctx2, 'fd, 'io) filter = ('ctx1, 'fd, 'io) service -> ('ctx2, 'fd, 'io) service
type ('ctx, 'fd, 'io) t = route -> ('ctx, 'fd, 'io) service

val scope : route -> ('ctx, 'fd, 'io) t -> ('ctx, 'fd, 'io) service
val filter : ('ctx1, 'ctx2, 'fd, 'io) filter -> ('ctx1, 'ctx2, 'fd, 'io) filter

val serve : ?port:int -> (unit, Httpaf_lwt_unix.Server.socket, unit Lwt.t) t -> unit Lwt.t
(** [serve ?port server] starts the top-level [server] listening on
    [port]. Top-level servers must have no context i.e. their context is
    [()]. *)

(*
let reject_ua f continue req = match Request.header "user-agent" req with
  | Some ua when f ua ->
    Response.status ~msg:"Please upgrade your browser" `Unauthorized
  | _ -> continue req

let index _req = Response.status ~msg:"Hello World" `OK
let msie = Str.regex ".*MSIE.*"
let contains_msie string = Str.string_match msie string 0

let server = function
  | `GET, [""] -> filter reject_ua contains_msie index
  | _ -> Response.status `NotFound

let () = server |> serve |> Lwt_main.run

val auth : ('a, < userid : string; prev : 'a >) Filter.t
  = 'a service -> < userid : string > service

val json : ('a, < body : Ezjsonm.t; prev : 'a >) Filter.t
  = 'a service -> < body : Ezjsonm.t; prev : 'a > service
*)
