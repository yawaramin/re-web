module H = Httpaf

type 'ctx t = {
  ctx : 'ctx;
  reqd : (Lwt_unix.file_descr, unit Lwt.t) Httpaf.Reqd.t;
}

let make reqd = {ctx = (); reqd}

let body request =
  let request_body = H.Reqd.request_body request.reqd in
  let stream, push_to_stream = Lwt_stream.create () in
  let on_eof () = push_to_stream None in
  let rec on_read bigstring ~off ~len =
    push_to_stream (Some {Body.off; len; bigstring});
    H.Body.schedule_read request_body ~on_eof ~on_read
  in
  H.Body.schedule_read request_body ~on_eof ~on_read;
  Body.Multi stream

let body_string ?(buf_size=Lwt_io.default_buffer_size ()) request =
  let request_body = H.Reqd.request_body request.reqd in
  let body, set_body = Lwt.wait () in
  let buffer = Buffer.create buf_size in
  let on_eof () =
    buffer |> Buffer.contents |> Lwt.wakeup_later set_body
  in
  let rec on_read data ~off:_ ~len:_ =
    data |> Bigstringaf.to_string |> Buffer.add_string buffer;
    H.Body.schedule_read request_body ~on_eof ~on_read
  in
  H.Body.schedule_read request_body ~on_eof ~on_read;
  body

let context {ctx; _} = ctx

let header name {reqd; _} =
  let {H.Request.headers; _} = H.Reqd.request reqd in
  H.Headers.get headers name

let headers name {reqd; _} =
  let {H.Request.headers; _} = H.Reqd.request reqd in
  H.Headers.get_multi headers name
