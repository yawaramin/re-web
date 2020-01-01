module type S = sig
  module Service : Service.S

  type ('ctx1, 'ctx2, 'resp) t =
    ('ctx2, 'resp) Service.t -> ('ctx1, 'resp) Service.t
  (** A filter transforms a service. It can change the request (usually
      by changing the request context) or the response (by actually
      running the service and then modifying its response).

      Filters can be composed using function composition. *)

  val basic_auth : ('ctx1, < username : string; password : string; prev : 'ctx1 >, _ Response.t) t
  (** [basic_auth] decodes and stores the login credentials sent with
      the [Authorization] header or returns a 401 Unauthorized error if
      there is none. *)

  val bearer_auth : ('ctx1, < bearer_token : string; prev : 'ctx1 >, _ Response.t) t
  (** [bearer_auth] stores the bearer token sent with the
      [Authorization] header or returns a 401 Unauthorized error if
      there is none. *)

  val body_form : ('ctor, 'ty) Form.t -> (unit, < form : 'ty >, [> Response.http]) t
  (** [body_form typ] is a filter that decodes a web form in the request
      body and puts it inside the request for the next service. The
      decoding is done as specified by the form definition [typ]. If the
      form fails to decode, it short-circuits and returns a 400 Bad
      Request. *)

  val body_json : (unit, < body : Ezjsonm.t >, [> Response.http]) t
  (** [body_json] is a filter that transforms a 'root' service (i.e. one
      with [unit] context) into a service with a context containing the
      request body. If the request body fails to parse as valid JSON, it
      short-circuits and returns a 400 Bad Request. *)

  val body_json_decode :
    (Ezjsonm.t -> ('ty, exn) result) ->
    (< body : Ezjsonm.t >, < body : 'ty >, [> Response.http]) t
  (** [body_json_decode decoder] is a filter that transforms a service
      with a parsed JSON structure in its context, to a service with a
      decoded value of type ['ty] in its context. If the request body
      fails to decode with [decoder], the filter short-circuits and
      returns a 400 Bad Request. *)

  val body_string : (unit, < body : string >, [> Response.http]) t
  (** [body_string] is a filter that transforms a 'root' service into a
      service whose context contains the request body as a single
      string. *)

  val query_form : ('ctor, 'ty) Form.t -> ('ctx1, < query : 'ty; prev : 'ctx1 >, _ Response.t) t
  (** [query_form typ] is a filter that decodes the request query (the
      part after the [?] in the endpoint) into a value of type ['ty] and
      stores it in the request context for the next service. The
      decoding and failure works in the same way as for [body_form]. *)
end

module Make(R : Request.S) : S
  with type ('fd, 'io) Service.Request.Reqd.t = ('fd, 'io) R.Reqd.t
  and type 'ctx Service.Request.t = 'ctx R.t = struct
  module Request = R
  module Service = Service.Make(Request)

  type ('ctx1, 'ctx2, 'resp) t =
    ('ctx2, 'resp) Service.t -> ('ctx1, 'resp) Service.t

  let get_auth request =
    let open Let.Option in
    let* value = Request.header "Authorization" request in
    match String.split_on_char ' ' value with
    | [typ; credentials] -> Some (typ, credentials)
    | _ -> None

  let bad_request message = `Bad_request
    |> Response.of_status ~message
    |> Lwt.return

  let unauthorized = `Unauthorized |> Response.of_status |> Lwt.return

  let basic_auth next request = match get_auth request with
    | Some ("Basic", credentials) ->
      begin match Base64.decode_exn credentials with
      | credentials ->
        begin match String.split_on_char ':' credentials with
        | [username; password] ->
          next {
            request with Request.ctx = object
              method username = username
              method password = password
              method prev = request.ctx
            end
          }
        | _ -> unauthorized
        end
      | exception _ -> unauthorized
      end
    | _ -> unauthorized

  let bearer_auth next request = match get_auth request with
    | Some ("Bearer", token) ->
      next {
        request with Request.ctx = object
          method bearer_token = token
          method prev = request.ctx
        end
      }
    | _ -> unauthorized

  let set_body body request =
    { request with Request.ctx = object method body = body end }

  let body_json next request =
    let open Let.Lwt in
    let* body = Request.body_string request in
    match Ezjsonm.from_string body with
    | body -> request |> set_body body |> next
    | exception Ezjsonm.Parse_error (_, string) ->
      bad_request ("ReWeb.Filter.body_json: " ^ string)
    | exception Assert_failure (_, _, _) ->
      bad_request "ReWeb.Filter.body_json: not a JSON document"

  let body_json_decode decoder next request =
    match decoder (Request.context request)#body with
    | Ok body -> request |> set_body body |> next
    | Error exn -> exn |> Printexc.to_string |> bad_request

  let body_string next request =
    let open Let.Lwt in
    let* body = Request.body_string request in
    request |> set_body body |> next

  let body_form typ next request =
    match Request.header "content-type" request with
    | Some "application/x-www-form-urlencoded" ->
      let open Let.Lwt in
      let* body = Request.body_string request in
      begin match Form.decoder typ body with
      | Ok obj ->
        next { request with Request.ctx = object method form = obj end }
      | Error string -> bad_request string
      end
    | _ ->
      bad_request "ReWeb.Filter.form: request content-type is not form"

  let query_form typ next request =
    match Form.decoder typ request.Request.query with
    | Ok obj ->
      next {
        request with Request.ctx = object
          method query = obj
          method prev = request.ctx
        end
      }
    | Error string -> bad_request string
end

