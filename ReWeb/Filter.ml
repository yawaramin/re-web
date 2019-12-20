type ('ctx1, 'ctx2) t = 'ctx2 Server.service -> 'ctx1 Server.service

let get_auth request =
  Option.bind (Request.header "Authorization" request) (fun value ->
    match String.split_on_char ' ' value with
    | [typ; credentials] -> Some (typ, credentials)
    | _ -> None)

let unauthorized = "Unauthorized"
  |> Response.text ~status:`Unauthorized
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
  let open Lwt_let in
  let* body = Request.body_string request in
  next {
    request with Request.ctx = object
      method body = Ezjsonm.from_string body
    end;
  }

let body_string next request =
  let open Lwt_let in
  let* body = Request.body_string request in
  next { request with Request.ctx = object method body = body end }

