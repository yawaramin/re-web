module H = Httpaf

module ReqdBody = struct
  type _ t = {
    chunks : Bigstringaf.t H.IOVec.t array;
    length : int;
    mutable index : int;
  }

  let schedule_read body ~on_eof ~on_read =
    if body.index = body.length then on_eof ()
    else
      let { H.IOVec.buffer; off; len } = body.chunks.(body.index) in
      body.index <- succ body.index;
      on_read buffer ~off ~len
end

module Reqd = struct
  module Body = ReqdBody
  type (_, _) t = H.Request.t * [`read] Body.t

  let request = fst
  let request_body = snd
end

module Request = ReWeb__Request.Make(ReqdBody)(Reqd)

let iovec string =
  let off = 0 in
  let len = String.length string in
  { H.IOVec.buffer = Bigstringaf.of_string ~off ~len string; off; len }

let body strings = {
  ReqdBody.chunks = Array.map iovec strings;
  length = Array.length strings;
  index = 0;
}

let request body_strings =
  Request.make "" (H.Request.create `GET "", body body_strings)

let to_string { H.IOVec.buffer; off; len } =
  Bigstringaf.substring ~off ~len buffer

open Alcotest
open Alcotest_lwt

let tests = "Request", [
  test_case "body - empty" `Quick begin fun _ () ->
    [||]
    |> request 
    |> Request.body
    |> ReWeb.Body.to_stream
    |> Lwt_stream.is_empty
    |> Lwt.map @@ check bool "" true
  end;

  test_case "body - single chunk" `Quick begin fun _ () ->
    let value = "a" in
    [|value|]
    |> request
    |> Request.body
    |> ReWeb.Body.to_stream
    |> Lwt_stream.to_list
    |> Lwt.map @@ fun values ->
      values |> List.map to_string |> check (list string) "" [value]
  end;

  test_case "body - multiple chunks" `Quick begin fun _ () ->
    [|"a"; "b"; "c"|]
    |> request
    |> Request.body
    |> ReWeb.Body.to_stream
    |> Lwt_stream.to_list
    |> Lwt.map @@ fun values ->
      values
      |> List.map to_string
      |> check (list string) "" ["a"; "b"; "c"]
  end;

  test_case "body_string - empty" `Quick begin fun _ () ->
    [||]
    |> request
    |> Request.body_string
    |> Lwt.map @@ check string "" ""
  end;

  test_case "body_string - single chunk" `Quick begin fun _ () ->
    let value = "a" in
    [|value|]
    |> request
    |> Request.body_string
    |> Lwt.map @@ check string "" value
  end;

  test_case "body_string - multiple chunks" `Quick begin fun _ () ->
    [|"a"; "b"|]
    |> request
    |> Request.body_string
    |> Lwt.map @@ check string "" "ab"
  end;
]

