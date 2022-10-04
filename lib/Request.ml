module type BODY = sig
  type _ t

  val schedule_read :
    [`read] t ->
    on_eof:(unit -> unit) ->
    on_read:(Bigstringaf.t -> off:int -> len:int -> unit) ->
    unit
end
(** This interface abstracts away the Httpaf body type. *)

module type REQD = sig
  module Body : BODY
  type t

  val request : t -> Httpaf.Request.t
  val request_body : t -> [`read] Body.t
end
(** This interface abstracts away the Httpaf request descriptor. *)

module type S = sig
  module Reqd : REQD

  type 'ctx t
  (** A request. ['ctx] is the type of the request context which can be
      updated by setting a new context. It is recommended to do so in a
      way that preserves the old context (if there is one), e.g. inside
      an OCaml object with a [prev] method that points to the old
      context. *)

  val body : _ t -> Eio.Flow.source

  val body_form_raw :
    ?buf_size:int ->
    unit t ->
    ((string * string list) list, string) result
  (** [body_form_raw ?buf_size request] returns the request body form decoded
      into an association list, internally using a buffer of size [buf_size] with
      a default configured by {!Reweb.Cfg.S.buf_size}.

      @since 0.7.0 *)

  val body_string : ?buf_size:int -> unit t -> string
  (** [body_string ?buf_size request] returns the request body
      converted into a string, internally using a buffer of size
      [buf_size] with a default configured by {!Reweb.Config.S.buf_size}. *)

  val context : 'ctx t -> 'ctx

  val cookies : _ t -> (string * string) list

  val header : string -> _ t -> string option
  (** [header name request] gets the last value corresponding to the given header,
      if present. *)

  val headers : string -> _ t -> string list
  (** [headers name request] gets all the values corresponding to the given
      header. *)

  val make : string -> Reqd.t -> unit t
  (** [make query reqd] returns a new request containing the given [query] and
      Httpaf [reqd]. *)

  val meth : _ t -> Httpaf.Method.t
  (** [meth request] gets the request method ([`GET], [`POST], etc.). *)

  val query : _ t -> string
  (** [query request] gets the query string of the [request]. This is anything
      following the [?] in the request path, otherwise an empty string. *)

  val set_context : 'ctx2 -> 'ctx1 t -> 'ctx2 t
  (** [set_context ctx request] is an updated [request] with the given context
      [ctx]. *)
end

module H = Httpaf

module Make(R : REQD) = struct
  module B = R.Body
  module Reqd = R

  type 'ctx t = { ctx : 'ctx; query : string; reqd : Reqd.t }

  let body { reqd; _ } =
    let reader = Reqd.request_body reqd in
    let cstructs = ref [] in
    let promise, resolver = Eio.Promise.create () in
    let on_eof () = !cstructs
      |> List.rev
      |> Eio.Flow.cstruct_source
      |> Eio.Promise.resolve resolver
    in
    let rec on_read buffer ~off ~len =
      let buffer = Bigstringaf.copy buffer ~off ~len in
      cstructs := Cstruct.of_bigarray ~len buffer :: !cstructs;
      B.schedule_read reader ~on_eof ~on_read;
      Eio.Fiber.yield ()
    in
    B.schedule_read reader ~on_eof ~on_read;
    Eio.Promise.await promise

  let body_string ?(buf_size=Reweb_cfg.buf_size) request =
    let bod = body request in
    let buf = Buffer.create buf_size in
    let sink = Eio.Flow.buffer_sink buf in
    Eio.Flow.copy bod sink;
    Buffer.contents buf

  let context { ctx; _ } = ctx

  let header name { reqd; _ } =
    let { H.Request.headers; _ } = Reqd.request reqd in
    H.Headers.get headers name

  let body_form_raw ?buf_size request =
    match header "content-type" request with
    | Some "application/x-www-form-urlencoded" ->
      (* TODO: implement a form query decoder that works more like what
         one would expect, i.e. understanding repeated (array) fields
         like [a[]=1&a[]=2], and erroring on invalid form data like [a]. *)
      let ok body = Ok (Uri.query_of_encoded body) in
      request |> body_string ?buf_size |> ok
    | _ -> Error "request content-type is not form"

  let headers name { reqd; _ } =
    let { H.Request.headers; _ } = Reqd.request reqd in
    H.Headers.get_multi headers name

  let parse_cookie string =
    match string |> String.trim |> String.split_on_char '=' with
    | [name; value] -> Some (name, value)
    | _ -> None

  let cookie_of_header value = value
    |> String.split_on_char ';'
    |> List.filter_map parse_cookie

  let cookies request = request
    |> headers "cookie"
    |> List.map cookie_of_header
    |> List.flatten

  let make query reqd = { ctx = (); query; reqd }
  let meth { reqd; _ } = (Reqd.request reqd).H.Request.meth
  let query { query; _ } = query
  let set_context ctx request = { request with ctx }
end

