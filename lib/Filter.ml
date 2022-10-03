module Header = Reweb_header

module type S = sig
  module Service : Service.S

  type ('ctx1, 'ctx2) t = 'ctx2 Service.t -> 'ctx1 Service.t
  (** A filter transforms a service. It can change the request (usually by
      changing the request context) or the response (by actually running the
      service and then modifying its response).

      Filters can be composed using function composition. *)

  val basic_auth : ('ctx1, < username : string; password : string; prev : 'ctx1 >) t
  (** [basic_auth] decodes and stores the login credentials sent with
      the [Authorization] header or returns a 401 Unauthorized error if
      there is none. *)

  val bearer_auth : ('ctx1, < bearer_token : string; prev : 'ctx1 >) t
  (** [bearer_auth] stores the bearer token sent with the
      [Authorization] header or returns a 401 Unauthorized error if
      there is none. *)

  val body_form : ('ctor, 'ty) Form.t -> (unit, 'ty) t
  (** [body_form typ] is a filter that decodes a web form in the request body and
      puts it inside the request for the next service. The decoding is done as
      specified by the form definition [typ]. If the form fails to decode, it
      short-circuits and returns a 400 Bad Request. *)

  val body_json : (unit, Yojson.Safe.t) t
  (** [body_json] is a filter that transforms a 'root' service (i.e. one
      with [unit] context) into a service with a context containing the
      request body. If the request body fails to parse as valid JSON, it
      short-circuits and returns a 400 Bad Request. *)

  val body_json_decode :
    (Yojson.Safe.t -> ('ty, string) result) ->
    (Yojson.Safe.t, 'ty) t
  (** [body_json_decode decoder] is a filter that transforms a service with a
      parsed JSON structure in its context, to a service with a decoded value of
      type ['ty] in its context. If the request body fails to decode with
      [decoder], the filter short-circuits and returns a 400 Bad Request. *)

  val body_string : (unit, string) t
  (** [body_string] is a filter that transforms a 'root' service into a
      service whose context contains the request body as a single
      string. *)

  val cache_control : Header.CacheControl.t -> ('ctx, 'ctx) t
  (** [cache_control policy] is a filter that applies the caching [policy] to the
      HTTP response. *)

  val cors : Header.AccessControlAllowOrigin.t -> ('ctx, 'ctx) t
  (** [cors origin] adds an
      {{: https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Access-Control-Allow-Origin} Access-Control-Allow-Origin}
      header with the given [origin].

      {i Note} that it's upto you to pass in a well-formed origin string. The
      [Header.AccessControlAllowOrigin] module does not validate the origin
      string. *)

  val csp : Header.ContentSecurityPolicy.t -> ('ctx, 'ctx) t
  (** [csp directives] is a filter that applies the [Content-Security-Policy]
      header [directives] to the response. *)

  val hsts : Header.StrictTransportSecurity.t -> ('ctx, 'ctx) t
  (** [hsts value] is a filter that applies the HTTP Strict Transport Security
      header to the response. *)

  val query_form : ('ctor, 'ty) Form.t -> ('ctx, < query : 'ty; prev : 'ctx >) t
  (** [query_form typ] is a filter that decodes the request query (the part after
      the [?] in the endpoint) into a value of type ['ty] and stores it in the
      request context for the next service. The decoding and failure works in the
      same way as for [body_form]. *)
end

module H = Httpaf

module Make(R : Request.S) : S
  with type Service.Request.Reqd.t = R.Reqd.t
  and type 'ctx Service.Request.t = 'ctx R.t = struct
  module Service = Service.Make(R)

  type ('ctx1, 'ctx2) t = 'ctx2 Service.t -> 'ctx1 Service.t

  let get_auth request =
    let open Let.Option in
    let* value = R.header "Authorization" request in
    match String.split_on_char ' ' value with
    | [typ; credentials] -> Some (typ, credentials)
    | _ -> None

  let bad_request message = Response.of_status ~message `Bad_request
  let unauthorized = Response.of_status `Unauthorized

  let basic_auth next request = match get_auth request with
    | Some ("Basic", credentials) ->
      begin match Base64.decode_exn credentials with
      | credentials ->
        begin match String.split_on_char ':' credentials with
        | [username; password] ->
          let ctx = object
            method username = username
            method password = password
            method prev = R.context request
          end
          in
          request
          |> R.set_context ctx
          |> next
        | _ -> unauthorized
        end
      | exception _ -> unauthorized
      end
    | _ -> unauthorized

  let bearer_auth next request = match get_auth request with
    | Some ("Bearer", token) ->
      let ctx = object
        method bearer_token = token
        method prev = R.context request
      end
      in
      request
      |> R.set_context ctx
      |> next
    | _ -> unauthorized

  let body_json_bad string =
    bad_request ("ReWeb.Filter.body_json: " ^ string)

  let body_json next request =
    match Yojson.Safe.from_string @@ R.body_string request with
    | ctx -> request |> R.set_context ctx |> next
    | exception Yojson.Json_error string -> body_json_bad string

  let body_json_decode decoder next request =
    match request |> R.context |> decoder with
    | Ok ctx -> request |> R.set_context ctx |> next
    | Error string -> bad_request string

  let body_string next request =
    let ctx = R.body_string request in
    request |> R.set_context ctx |> next

  let body_form typ next request = match R.body_form_raw request with
    | Ok raw ->
      begin match Form.decode typ raw with
      | Ok ctx -> request |> R.set_context ctx |> next
      | Error string -> bad_request string
      end
    | Error string ->
      bad_request ("ReWeb.Filter.form: " ^ string)

  let cache_control policy next request = request
    |> next
    |> Response.add_header
      ~name:"cache-control"
      ~value:(Header.CacheControl.to_string policy)

  let cors origin next request = request
    |> next
    |> Response.add_headers [
      Header.AccessControlAllowOrigin.to_header origin;
      "vary", "Origin";
    ]

  let csp directives next request =
    let open Header.ContentSecurityPolicy in
    let headers = [to_header directives] in
    let headers =
      if has_report_to directives.report_to
      then report_to_header directives :: headers
      else headers
    in
    request
    |> next
    |> Response.add_headers headers

  let hsts value next request =
    let name, value = Header.StrictTransportSecurity.to_header value in
    request
    |> next
    |> Response.add_header ~name ~value

  let query_form typ next request =
    match request |> R.query |> Form.decoder typ with
    | Ok obj ->
      let ctx = object
        method query = obj
        method prev = R.context request
      end
      in
      request |> R.set_context ctx |> next
    | Error string -> bad_request string
end
