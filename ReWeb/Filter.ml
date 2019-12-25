type ('ctx1, 'ctx2) t = 'ctx2 Server.service -> 'ctx1 Server.service

let get_auth request =
  Option.bind (Request.header "Authorization" request) (fun value ->
    match String.split_on_char ' ' value with
    | [typ; credentials] -> Some (typ, credentials)
    | _ -> None)

let bad_request string = string
  |> Response.of_text ~status:`Bad_request
  |> Lwt.return

let unauthorized = "Unauthorized"
  |> Response.of_text ~status:`Unauthorized
  |> Lwt.return

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

let body_json next request =
  let open Let.Lwt in
  let* body = Request.body_string request in
  match Ezjsonm.from_string body with
  | body ->
    next { request with Request.ctx = object method body = body end }
  | exception Ezjsonm.Parse_error (_, string) ->
    bad_request ("ReWeb.Filter.body_json: " ^ string)
  | exception Assert_failure (_, _, _) ->
    bad_request "ReWeb.Filter.body_json: not a JSON document"

let body_string next request =
  let open Let.Lwt in
  let* body = Request.body_string request in
  next { request with Request.ctx = object method body = body end }

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

