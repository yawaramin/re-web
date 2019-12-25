type headers = (string * string) list

module New : sig
  type request_body =
    ?config:Piaf.Config.t ->
    ?headers:headers ->
    ?body:Body.t ->
    string ->
    (Response.t, string) Lwt_result.t
  (** The type of request functions which send a request body. *)

  type request_nobody =
    ?config:Piaf.Config.t ->
    ?headers:headers ->
    string ->
    (Response.t, string) Lwt_result.t
  (** The type of request functions which don't send a request body. *)

  val delete : request_body
  val get : request_nobody
  val head : request_nobody
  val patch : request_body
  val post : request_body
  val put : request_body

  val request :
    ?config:Piaf.Config.t ->
    ?headers:headers ->
    ?body:Body.t ->
    meth:Piaf.Method.t ->
    string ->
    (Response.t, string) Lwt_result.t
  (** Make a request not covered by the above functions. *)
end
(** Make requests with a one-shot i.e. stateless client. *)

