type ('ctx1, 'ctx2) t = 'ctx2 Server.service -> 'ctx1 Server.service

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
