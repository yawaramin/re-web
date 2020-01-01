(** The request functions below return a response of type
    [([> Response.http], string) Lwt_result.t]. This is a promise
    containing a [result] of either [Ok response] where [response] is an
    HTTP response, or a [string] containing an error message. *)

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

val config : config
(** Use this [config] value to override the default config in client
    requests. *)

module New : sig
  type 'resp request_body =
    ?config:config ->
    ?headers:headers ->
    ?body:Body.t ->
    string ->
    ([> Response.http] as 'resp, string) Lwt_result.t
  (** The type of request functions which send a request body. *)

  type 'resp request_nobody =
    ?config:config ->
    ?headers:headers ->
    string ->
    ([> Response.http] as 'resp, string) Lwt_result.t
  (** The type of request functions which don't send a request body. *)

  val delete : [> Response.http] request_body
  val get : [> Response.http] request_nobody
  val head : [> Response.http] request_nobody
  val patch : [> Response.http] request_body
  val post : [> Response.http] request_body
  val put : [> Response.http] request_body

  val request :
    ?config:config->
    ?headers:headers ->
    ?body:Body.t ->
    meth:Piaf.Method.t ->
    string ->
    ([> Response.http], string) Lwt_result.t
  (** Make a request not covered by the above functions. *)
end
(** Make requests with a one-shot i.e. stateless client. *)

