type config = Piaf.Config.t = {
  follow_redirects : bool;
  max_redirects : int;
  allow_insecure : bool;
  max_http_version : Piaf.Versions.HTTP.t;
  h2c_upgrade : bool;
  http2_prior_knowledge : bool;
  cacert : string option;
  capath : string option;
  min_tls_version : Piaf.Versions.TLS.t;
  max_tls_version : Piaf.Versions.TLS.t;
  tcp_nodelay : bool;
  connect_timeout : float;
}
(** See the Piaf module documentation for more information on these
    options. *)

type headers = (string * string) list

module New : sig
  type request_body =
    ?config:config ->
    ?headers:headers ->
    ?body:Body.t ->
    string ->
    (Response.t, string) Lwt_result.t
  (** The type of request functions which send a request body. *)

  type request_nobody =
    ?config:config ->
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
    ?config:config->
    ?headers:headers ->
    ?body:Body.t ->
    meth:Piaf.Method.t ->
    string ->
    (Response.t, string) Lwt_result.t
  (** Make a request not covered by the above functions. *)
end
(** Make requests with a one-shot i.e. stateless client. *)

