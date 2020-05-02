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
  module Config : ReWeb__Config.S
  module Reqd : REQD

  type 'ctx t
  (** A request. ['ctx] is the type of the request context which can be
      updated by setting a new context. It is recommended to do so in a
      way that preserves the old context (if there is one), e.g. inside
      an OCaml object with a [prev] method that points to the old
      context. *)

  val body : unit t -> Body.t
  (** [body(request)] gets the [request] body. There is a chance that
      the body may already have been read, in which case trying to read
      it again will error. However in a normal request pipeline as
      bodies are read by filters, that should be minimized. *)

  val body_string : ?buf_size:int -> unit t -> string Lwt.t
  (** [body_string(?buf_size, request)] returns the request body
      converted into a string, internally using a buffer of size
      [buf_size] with a default configured by {!ReWeb.Config.S.buf_size}. *)

  val context : 'ctx t -> 'ctx

  val cookies : _ t -> (string * string) list

  val header : string -> _ t -> string option
  (** [header(name, request)] gets the last value corresponding to the
      given header, if present. *)

  val headers : string -> _ t -> string list
  (** [headers(name, request)] gets all the values corresponding to the
      given header. *)

  val make : string -> Reqd.t -> unit t
  (** [make(query, reqd)] returns a new request containing the given
      [query] and Httpaf [reqd]. *)

  val meth : _ t -> Httpaf.Method.t
  (** [meth(request)] gets the request method ([`GET], [`POST], etc.). *)

  val query : _ t -> string
  (** [query(request)] gets the query string of the [request]. This is
      anything following the [?] in the request path, otherwise an empty
      string. *)

  val set_context : 'ctx2 -> 'ctx1 t -> 'ctx2 t
  (** [set_context(ctx, request)] is an updated [request] with the given
      context [ctx]. *)
end

module H = Httpaf

module Make
  (C : ReWeb__Config.S)
  (B : BODY)
  (R : REQD with type 'rw Body.t = 'rw B.t) = struct
  module Config = C
  module Reqd = R

  type 'ctx t = { ctx : 'ctx; query : string; reqd : Reqd.t }

  let body request =
    let request_body = Reqd.request_body request.reqd in
    let stream, push_to_stream = Lwt_stream.create () in
    let on_eof () = push_to_stream None in
    let rec on_read buffer ~off ~len =
      push_to_stream (Some {
        H.IOVec.off;
        len;
        buffer = Bigstringaf.copy buffer ~off ~len
      });
      B.schedule_read request_body ~on_eof ~on_read
    in
    B.schedule_read request_body ~on_eof ~on_read;
    Body.of_stream stream

  let body_string ?(buf_size=Config.buf_size) request =
    let request_body = Reqd.request_body request.reqd in
    let body, set_body = Lwt.wait () in
    let buffer = Buffer.create buf_size in
    let on_eof () =
      buffer |> Buffer.contents |> Lwt.wakeup_later set_body
    in
    let rec on_read data ~off ~len =
      data |> Bigstringaf.substring ~off ~len |> Buffer.add_string buffer;
      B.schedule_read request_body ~on_eof ~on_read
    in
    B.schedule_read request_body ~on_eof ~on_read;
    body

  let context { ctx; _ } = ctx

  let header name { reqd; _ } =
    let { H.Request.headers; _ } = Reqd.request reqd in
    H.Headers.get headers name

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

