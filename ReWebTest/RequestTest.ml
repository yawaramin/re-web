module H = Httpaf

module ReqdBody = struct
  type _ t = {
    chunks : Bigstringaf.t H.IOVec.t array;
    length : int;
    mutable index : int;
    mutable curr : Bigstringaf.t H.IOVec.t option;
  }

  (* We need to reuse the same buffer when we call [on_read] because
     that's how Httpaf itself works. See
     https://github.com/inhabitedtype/httpaf/issues/140#issuecomment-517072327 *)
  let schedule_read body ~on_eof ~on_read =
    if body.index = body.length then on_eof ()
    else begin
      body.curr <- Some body.chunks.(body.index);
      body.index <- succ body.index;
      match body.curr with
      | Some { H.IOVec.buffer; off; len } -> on_read buffer ~off ~len
      | None -> failwith "Unreachable branch"
    end
end

module Reqd = struct
  module Body = ReqdBody
  type t = H.Request.t * [`read] Body.t

  let request = fst
  let request_body = snd
end

module Request = ReWeb__Request.Make(ReWeb.Config.Default)(ReqdBody)(Reqd)

let iovec string =
  let off = 0 in
  let len = String.length string in
  { H.IOVec.buffer = Bigstringaf.of_string ~off ~len string; off; len }

let body strings = {
  Reqd.Body.chunks = Array.map iovec strings;
  length = Array.length strings;
  index = 0;
  curr = None;
}

let request ?(headers=[]) body_strings =
  let headers = H.Headers.of_list headers in
  Request.make "" (H.Request.create ~headers `GET "", body body_strings)

let to_string { H.IOVec.buffer; off; len } =
  Bigstringaf.substring ~off ~len buffer

open Alcotest

let cookies = list (pair string string)

let s = "ReWeb.Request", [
  Alcotest_lwt.test_case "body - empty" `Quick begin fun _ () ->
    [||]
    |> request 
    |> Request.body
    |> ReWeb.Body.to_stream
    |> Lwt_stream.is_empty
    |> Lwt.map @@ check bool "" true
  end;

  Alcotest_lwt.test_case "body - single chunk" `Quick begin fun _ () ->
    let value = "a" in
    [|value|]
    |> request
    |> Request.body
    |> ReWeb.Body.to_stream
    |> Lwt_stream.to_list
    |> Lwt.map @@ fun values ->
      values |> List.map to_string |> check (list string) "" [value]
  end;

  Alcotest_lwt.test_case "body - multiple chunks" `Quick begin fun _ () ->
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

  Alcotest_lwt.test_case "body_string - empty" `Quick begin fun _ () ->
    [||]
    |> request
    |> Request.body_string
    |> Lwt.map @@ check string "" ""
  end;

  Alcotest_lwt.test_case "body_string - single chunk" `Quick begin fun _ () ->
    let value = "a" in
    [|value|]
    |> request
    |> Request.body_string
    |> Lwt.map @@ check string "" value
  end;

  Alcotest_lwt.test_case "body_string - multiple chunks" `Quick begin fun _ () ->
    [|"a"; "b"|]
    |> request
    |> Request.body_string
    |> Lwt.map @@ check string "" "ab"
  end;

  test_case "cookies - single" `Quick begin fun () ->
    let session = "session" in
    let value = "session cookie value" in
    [||]
    |> request ~headers:["cookie", session ^ "=" ^ value]
    |> Request.cookies
    |> List.assoc_opt session
    |> check (option string) "" @@ Some value
  end;

  test_case "cookies - multiple" `Quick begin fun () ->
    [||]
    |> request ~headers:["cookie", "a=b; c=d"]
    |> Request.cookies
    |> check cookies "" ["a", "b"; "c", "d"]
  end;

  test_case "cookies - multiple headers" `Quick begin fun () ->
    [||]
    |> request ~headers:["cookie", "a=b"; "cookie", "c=d; e=f"]
    |> Request.cookies
    |> check cookies "" ["a", "b"; "c", "d"; "e", "f"]
  end;
]

