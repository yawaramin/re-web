open Httpaf

type 'ctx t = {ctx : 'ctx; reqd: Reqd.t}

(*
module BodyBuilder = struct
  let build ~len body_builder = Bigstringaf.sub ~off:0 ~len body_builder

  let make ?(size_hint=Lwt_io.default_buffer_size ()) () =
    Bigstringaf.create size_hint

  let write ~off ~len ~data body_builder =
    let size = Bigstringaf.length body_builder in
    let new_len = off + len in
    let body_builder =
      if new_len >= size then begin
        let result = make ~size_hint:(2 * new_len) () in
        Bigstringaf.blit
          body_builder
          ~src_off:0
          result
          ~dst_off:0
          ~len:(size - 1);
        result
      end else body_builder
    in
    Bigstringaf.blit data ~src_off:0 body_builder ~dst_off:off ~len
end
*)

let ctx {ctx; _} = ctx

let header name {reqd; _} =
  let {Request.headers; _} = Reqd.request reqd in
  Headers.get headers name

let headers name {reqd; _} =
  let {Request.headers; _} = Reqd.request reqd in
  Headers.get_multi headers name

let make reqd = {
  body = ()
    |> Lwt_io.default_buffer_size
    |> Bigstringaf.create
    |> Lwt.return;
  body_read = false;
  reqd
}

let read request =
  if request.body_read then request else

  let request_body = Reqd.request_body request.reqd in
  let body, set_body = Lwt.wait () in
  let body_builder = BodyBuilder.make () in
  let size = ref 0 in
  let on_eof () = body_builder
    |> BodyBuilder.build ~len:!size
    |> Lwt.wakeup_later set_body
  in
  let rec on_read data ~off ~len =
    BodyBuilder.write ~off ~len ~data body_builder;
    size := !size + len;
    gobble ()
  and gobble () = Body.schedule_read request_body ~on_eof ~on_read in

  gobble ();
  {request with body; body_read = true}

let body {body; body_read; _} =
  if body_read then body else raise Not_found

let body_json request = request |> body |> Lwt.map begin fun body ->
  let len = Bigstringaf.length body in
  body |> Bigstringaf.substring ~off:0 ~len |> Ezjsonm.from_string
end
