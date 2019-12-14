open Httpaf

type 'ctx t = {ctx : 'ctx; reqd : Reqd.t}

let make reqd = {ctx = (); reqd}

let context {ctx; _} = ctx

let header name {reqd; _} =
  let {Request.headers; _} = Reqd.request reqd in
  Headers.get headers name

let headers name {reqd; _} =
  let {Request.headers; _} = Reqd.request reqd in
  Headers.get_multi headers name

let body request =
  let request_body = Reqd.request_body request.reqd in
  let ctx, push_to_stream = Lwt_stream.create () in
  let on_eof () = push_to_stream None in
  let rec on_read data ~off:_ ~len:_ =
    push_to_stream (Some data);
    Body.schedule_read request_body ~on_eof ~on_read
  in
  Body.schedule_read request_body ~on_eof ~on_read;
  {request with ctx}
