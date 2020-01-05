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
  (** [body_form(typ)] is a filter that decodes a web form in the
      request body and puts it inside the request for the next service.
      The decoding is done as specified by the form definition [typ]. If
      the form fails to decode, it short-circuits and returns a 400 Bad
      Request. *)

  val body_json : (unit, < body : Ezjsonm.t >, [> Response.http]) t
  (** [body_json] is a filter that transforms a 'root' service (i.e. one
      with [unit] context) into a service with a context containing the
      request body. If the request body fails to parse as valid JSON, it
      short-circuits and returns a 400 Bad Request. *)

  val body_json_decode :
    (Ezjsonm.t -> ('ty, exn) result) ->
    (< body : Ezjsonm.t >, < body : 'ty >, [> Response.http]) t
  (** [body_json_decode(decoder)] is a filter that transforms a service
      with a parsed JSON structure in its context, to a service with a
      decoded value of type ['ty] in its context. If the request body
      fails to decode with [decoder], the filter short-circuits and
      returns a 400 Bad Request. *)

  val body_string : (unit, < body : string >, [> Response.http]) t
  (** [body_string] is a filter that transforms a 'root' service into a
      service whose context contains the request body as a single
      string. *)

  val multipart_form :
    typ:('ctor, 'ty) Form.t ->
    (filename:string -> string -> string) ->
    (unit, < form : 'ty >, [> Response.http]) t
  (** [multipart_form(~typ, path)] is a filter that decodes multipart
      form data. [typ] must be provided but if you don't actually have
      any other fields in the form you can use [Form.empty] to decode
      into an 'empty' (unit) value.

      [path(~filename, name)] is used to get the filesystem absolute
      path to save the given [filename] with corresponding form field
      [name]. Note that [filename] is the basename, not the full path.
      Also that the file will be overwritten if it already exists on
      disk! This callback gives you a chance to sanitize incoming
      filenames before storing the files on disk. *)

  val query_form : ('ctor, 'ty) Form.t -> ('ctx1, < query : 'ty; prev : 'ctx1 >, _ Response.t) t
  (** [query_form(typ)] is a filter that decodes the request query (the
      part after the [?] in the endpoint) into a value of type ['ty] and
      stores it in the request context for the next service. The
      decoding and failure works in the same way as for [body_form]. *)
end

module H = Httpaf

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

  let multipart_ct_length = 30

  let chunk_to_string { H.IOVec.buffer; off; len } =
    Bigstringaf.substring buffer ~off ~len

  (* Complex because we need to keep track of files being uploaded *)
  let multipart_form ~typ path next request =
    match Request.meth request, Request.header "content-type" request with
    | `POST, Some content_type
      when String.length content_type > multipart_ct_length
      && String.sub content_type 0 multipart_ct_length = "multipart/form-data; boundary=" ->
      let stream = request
        |> Request.body
        |> Body.to_stream
        |> Lwt_stream.map chunk_to_string
      in
      let files = Hashtbl.create ~random:true 5 in
      let open Let.Lwt in
      let close _ file prev =
        let* () = prev in
        Lwt_unix.close file
      in
      let callback ~name ~filename string =
        let filename =
          path ~filename:(Filename.basename filename) name
        in
        let write file =
          let f () = string
            |> String.length
            |> Lwt_unix.write_string file string 0
            |> Lwt.map ignore
          in
          Lwt.catch f @@ fun exn ->
            exn |> Printexc.to_string |> Lwt_io.printf "ERROR: %s\n"
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
      let* fields = Lwt.catch f @@ fun exn ->
        let+ () = exn |> Printexc.to_string |> Lwt_io.printf "ERROR: %s" in
        []
      in
      let* () = Hashtbl.fold close files Lwt.return_unit in
      let fields = List.map (fun (k, v) -> k, [v]) fields in
      begin match Form.decode typ fields with
      | Ok obj ->
        next { request with Request.ctx = object method form = obj end }
      | Error string -> bad_request string
      end
    | _ ->
      bad_request "ReWeb.Filter.multipart_form: request is not well-formed"

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

