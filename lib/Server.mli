type path = string list

type route = Httpaf.Method.t * path
(** Pattern-matchable identifier of the request for routing purposes.
    Consists of:

    - HTTP method e.g. [`GET] and [`POST]
    - (String) list of path segments

    E.g., [GET /api/user/1] would be represented as
    [(`GET, ["api", "user", "1"])] *)

type 'ctx service = 'ctx Request.t -> Response.t Lwt.t
type ('ctx1, 'ctx2) filter = 'ctx1 service -> 'ctx2 service
type 'ctx t = route -> 'ctx service

val scope : route -> 'ctx t -> 'ctx service
val filter : ('ctx1, 'ctx2) filter -> ('ctx1, 'ctx2) filter
val serve : ?port:int -> 'ctx t -> unit Lwt.t

(*
let () =
  let open Server in

  let api = function
    | `GET, ["pets", id] -> Services.Pet.get id
    | `POST, ["pet"] -> Services.Pet.make
    | _ -> status `NotFound
  in
  let server = function
    | meth, "api" :: path ->
      api
      |> scope (meth, path)
      |> filter Filters.auth
      |> filter Filters.json
    | `POST, ["graphql"] -> Services.GraphQL.query
    | _ -> status `NotFound
  in
  server
  |> serve
  |> Lwt_main.run)

let reject_ua f continue req = match Request.header "user-agent" req with
  | Some ua when f ua ->
    Response.status ~msg:"Please upgrade your browser" `Unauthorized
  | _ -> continue req

let index _req = Response.status ~msg:"Hello World" `OK
let msie = Str.regex ".*MSIE.*"
let contains_msie string = Str.string_match msie string 0

let server = function
  | `GET, [""] -> filter reject_ua contains_msie index
  | _ -> fun _req -> Response.status `NotFound

let () = server |> serve |> Lwt_main.run

val auth : ('a, < userid : string; prev : 'a >) Filter.t
  = 'a service -> < userid : string > service

val json : ('a, < body : Ezjsonm.t; prev : 'a >) Filter.t
  = 'a service -> < body : Ezjsonm.t; prev : 'a > service
*)
