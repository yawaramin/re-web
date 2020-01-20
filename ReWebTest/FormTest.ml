open Alcotest
open ReWeb.Form

type user = { id : int; name : string }

let user id name = { id; name }

let form = make
  Field.[int "id"; "name" |> string |> ensure ((<>) "")]
  user

let s = "ReWeb.Form", [
  test_case "decoder - decode correctly" `Quick begin fun () ->
    match decoder form "id=1&name=Bob" with
    | Ok { id; name } ->
      check int "" 1 id;
      check string "" "Bob" name
    | Error message -> fail message
  end;

  test_case "decoder - error on bad input" `Quick begin fun () ->
    match decoder form "" with
    | Ok _ -> fail "should not decode bad input"
    | Error message ->
      check string "" "ReWeb.Form.decoder: could not find key id" message
  end;
]

