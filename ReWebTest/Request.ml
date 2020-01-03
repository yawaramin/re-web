module IOVec = Httpaf.IOVec

module ReqdBody = struct
  type _ t = {
    chunks : Bigstringaf.t IOVec.t array;
    length : int;
    mutable index : int;
  }

  let schedule_read body ~on_eof ~on_read =
    if body.index = body.length then on_eof ()
    else
      let { IOVec.buffer; off; len } = body.chunks.(body.index) in
      body.index <- succ body.index;
      on_read buffer ~off ~len
end

module Reqd = struct
  module Body = ReqdBody
  type (_, _) t = Httpaf.Request.t * [`read] Body.t

  let request = fst
  let request_body = snd
end

module Request = ReWeb__Request.Make(ReqdBody)(Reqd)

let iovec string =
  let off = 0 in
  let len = String.length string in
  { IOVec.buffer = Bigstringaf.of_string ~off ~len string; off; len }

let body strings = {
  ReqdBody.chunks = Array.map iovec strings;
  length = Array.length strings;
  index = 0;
}

open Alcotest
open Alcotest_lwt

let tests = "Request", [
  test_case "body_string - empty" `Quick begin fun _ () ->
    (Httpaf.Request.create `GET "", body [||])
    |> Request.make ""
    |> Request.body_string
    |> Lwt.map @@ check string "" ""
  end;

  test_case "body_string - single chunk" `Quick begin fun _ () ->
    let value = "a" in
    (Httpaf.Request.create `GET "", body [|value|])
    |> Request.make ""
    |> Request.body_string
    |> Lwt.map @@ check string "" value
  end;

  test_case "body_string - multiple chunks" `Quick begin fun _ () ->
    (Httpaf.Request.create `GET "", body [|"a"; "b"|])
    |> Request.make ""
    |> Request.body_string
    |> Lwt.map @@ check string "" "ab"
  end;
]

