module type S = sig
  module Config : Config.S
  module Service : Service.S

  type ('ctx1, 'ctx2, 'resp) t =
    ('ctx2, 'resp) Service.t -> ('ctx1, 'resp) Service.t
  (** A filter transforms a service. It can change the request (usually
      by changing the request context) or the response (by actually
      running the service and then modifying its response).

      Filters can be composed using function composition. *)

  val access_control_allow_origin :
    Header.AccessControlAllowOrigin.t ->
    ('ctx, 'ctx, [Response.http | Response.websocket]) t
  (** [access_control_allow_origin(origin)] adds an
      {{: https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Access-Control-Allow-Origin} Access-Control-Allow-Origin}
      header with the given [origin].

      {i Note} that it's upto you to pass in a well-formed origin
      string. The [Header.AccessControlAllowOrigin] module does not
      validate the origin string. *)

  val basic_auth : ('ctx1, < username : string; password : string; prev : 'ctx1 >, _ Response.t) t
  (** [basic_auth] decodes and stores the login credentials sent with
      the [Authorization] header or returns a 401 Unauthorized error if
      there is none. *)

  val bearer_auth : ('ctx1, < bearer_token : string; prev : 'ctx1 >, _ Response.t) t
  (** [bearer_auth] stores the bearer token sent with the
      [Authorization] header or returns a 401 Unauthorized error if
      there is none. *)

  val body_form : ('ctor, 'ty) Form.t -> (unit, 'ty, [> Response.http]) t
  (** [body_form(typ)] is a filter that decodes a web form in the
      request body and puts it inside the request for the next service.
      The decoding is done as specified by the form definition [typ]. If
      the form fails to decode, it short-circuits and returns a 400 Bad
      Request. *)

  val body_json : (unit, Ezjsonm.t, [> Response.http]) t
  (** [body_json] is a filter that transforms a 'root' service (i.e. one
      with [unit] context) into a service with a context containing the
      request body. If the request body fails to parse as valid JSON, it
      short-circuits and returns a 400 Bad Request. *)

  val body_json_decode :
    (Ezjsonm.t -> ('ty, exn) result) ->
    (Ezjsonm.t, 'ty, [> Response.http]) t
  (** [body_json_decode(decoder)] is a filter that transforms a service
      with a parsed JSON structure in its context, to a service with a
      decoded value of type ['ty] in its context. If the request body
      fails to decode with [decoder], the filter short-circuits and
      returns a 400 Bad Request. *)

  val body_string : (unit, string, [> Response.http]) t
  (** [body_string] is a filter that transforms a 'root' service into a
      service whose context contains the request body as a single
      string. *)

  val cache_control :
    Header.CacheControl.t ->
    ('ctx, 'ctx, [Response.http | Response.websocket]) t
  (** [cache_control(policy)] is a filter that applies the caching
      [policy] policy to the HTTP response. *)

  val hsts :
    Header.StrictTransportSecurity.t ->
    ('ctx, 'ctx, [Response.http | Response.websocket]) t
  (** [hsts(value)] is a filter that applies the HTTP Strict Transport
      Security header to the response. *)

  val multipart_form :
    typ:('ctor, 'ty) Form.t ->
    (filename:string -> string -> string) ->
    (unit, 'ty, [> Response.http]) t
  (** [multipart_form(~typ, path)] is a filter that decodes multipart
      form data. [typ] must be provided but if you don't actually have
      any other fields in the form you can use [Form.empty] to decode
      into an 'empty' (unit) value.

      [path(~filename, name)] is used to get the filesystem absolute
      path to save the given [filename] with corresponding form field
      [name]. Note that:

      - The file will be overwritten if it already exists on disk
      - [filename] is the basename, not the full path
      - The filter will short-circuit with a 401 Unauthorized error
        response if any of the files can't be opened for writing.

      This callback gives you a chance to sanitize incoming filenames
      before storing the files on disk. *)

  val query_form : ('ctor, 'ty) Form.t -> ('ctx, < query : 'ty; prev : 'ctx >, _ Response.t) t
  (** [query_form(typ)] is a filter that decodes the request query (the
      part after the [?] in the endpoint) into a value of type ['ty] and
      stores it in the request context for the next service. The
      decoding and failure works in the same way as for [body_form]. *)
end

module H = Httpaf

module Make(R : Request.S) : S
  with type ('fd, 'io) Service.Request.Reqd.t = ('fd, 'io) R.Reqd.t
  and type 'ctx Service.Request.t = 'ctx R.t = struct
  module Service = Service.Make(R)
  module Config = Service.Config

  type ('ctx1, 'ctx2, 'resp) t =
    ('ctx2, 'resp) Service.t -> ('ctx1, 'resp) Service.t

  let get_auth request =
    let open Let.Option in
    let* value = R.header "Authorization" request in
    match String.split_on_char ' ' value with
    | [typ; credentials] -> Some (typ, credentials)
    | _ -> None

  let bad_request message = `Bad_request
    |> Response.of_status ~message
    |> Lwt.return

  let unauthorized = `Unauthorized |> Response.of_status |> Lwt.return

  let access_control_allow_origin origin next request = request
    |> next
    |> Lwt.map @@ Response.add_header
      ~name:"access-control-allow-origin"
      ~value:(Header.AccessControlAllowOrigin.to_string origin)

  let basic_auth next request = match get_auth request with
    | Some ("Basic", credentials) ->
      begin match Base64.decode_exn credentials with
      | credentials ->
        begin match String.split_on_char ':' credentials with
        | [username; password] ->
          next {
            request with R.ctx = object
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
        request with R.ctx = object
          method bearer_token = token
          method prev = request.ctx
        end
      }
    | _ -> unauthorized

  let body_json next request =
    let open Let.Lwt in
    let* body = R.body_string request in
    match Ezjsonm.from_string body with
    | ctx -> next { request with ctx }
    | exception Ezjsonm.Parse_error (_, string) ->
      bad_request ("ReWeb.Filter.body_json: " ^ string)
    | exception Assert_failure (_, _, _) ->
      bad_request "ReWeb.Filter.body_json: not a JSON document"

  let body_json_decode decoder next request =
    match decoder request.R.ctx with
    | Ok ctx -> next { request with ctx }
    | Error exn -> exn |> Printexc.to_string |> bad_request

  let body_string next request =
    let open Let.Lwt in
    let* ctx = R.body_string request in
    next { request with ctx }

  let body_form typ next request =
    match R.header "content-type" request with
    | Some "application/x-www-form-urlencoded" ->
      let open Let.Lwt in
      let* body = R.body_string request in
      begin match Form.decoder typ body with
      | Ok ctx -> next { request with ctx }
      | Error string -> bad_request string
      end
    | _ ->
      bad_request "ReWeb.Filter.form: request content-type is not form"

  let cache_control policy next request = request
    |> next
    |> Lwt.map @@ Response.add_header
      ~name:"cache-control"
      ~value:(Header.CacheControl.to_string policy)

  let hsts value next request =
    let name, value = Header.StrictTransportSecurity.to_header value in
    request
    |> next
    |> Lwt.map @@ Response.add_header ~name ~value

  let multipart_ct_length = 30

  let chunk_to_string { H.IOVec.buffer; off; len } =
    Bigstringaf.substring buffer ~off ~len

  (* Complex because we need to keep track of files being uploaded *)
  let multipart_form ~typ path next request =
    match R.meth request, R.header "content-type" request with
    | `POST, Some content_type
      when String.length content_type > multipart_ct_length
      && String.sub content_type 0 multipart_ct_length = "multipart/form-data; boundary=" ->
      let stream = request
        |> R.body
        |> Body.to_stream
        |> Lwt_stream.map chunk_to_string
      in
      let files = Hashtbl.create ~random:true 5 in
      let open Let.Lwt in
      let close _ file prev =
        let* () = prev in
        Lwt_unix.close file
      in
      let cleanup () = Hashtbl.fold close files Lwt.return_unit in
      let callback ~name ~filename string =
        let filename =
          path ~filename:(Filename.basename filename) name
        in
        let write file = string
          |> String.length
          |> Lwt_unix.write_string file string 0
          |> Lwt.map ignore
        in
        match Hashtbl.find_opt files filename with
        | Some file -> write file
        | None ->
          let* file = Lwt_unix.openfile
            filename
            Unix.[O_CREAT; O_TRUNC; O_WRONLY; O_NONBLOCK]
            0o600
          in
          Hashtbl.add files filename file;
          write file
      in
      let f () =
        Multipart_form_data.parse ~stream ~content_type ~callback
      in
      let g fields =
        let* () = cleanup () in
        let fields = List.map (fun (k, v) -> k, [v]) fields in
        match Form.decode typ fields with
        | Ok ctx -> next { request with ctx }
        | Error string -> bad_request string
      in
      Lwt.try_bind f g begin fun exn ->
        let* () = cleanup () in
        begin match exn with
          | Unix.Unix_error (Unix.EPERM, _, _) -> unauthorized
          | _ ->
            let message = exn
              |> Printexc.to_string
              |> ((^) "ReWeb.Filter.multpart_form: ")
            in
            `Internal_server_error
            |> Response.of_status ~message
            |> Lwt.return
        end
      end
    | _ ->
      bad_request "ReWeb.Filter.multipart_form: request is not well-formed"

  let query_form typ next request =
    match Form.decoder typ request.R.query with
    | Ok obj ->
      next {
        request with R.ctx = object
          method query = obj
          method prev = request.R.ctx
        end
      }
    | Error string -> bad_request string
end

