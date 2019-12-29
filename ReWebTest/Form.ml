open ReWeb.Form

type user = { id : int; name : string }

let user id name = { id; name }

let form = make
  Field.[int "id"; "name" |> string |> ensure ((<>) "")]
  user

let%test "decoder - decode correctly" =
  match decoder form "id=1&name=Bob" with
  | Ok { id = 1; name = "Bob" } -> true
  | _ -> false

let%test "decoder - error on bad input" = match decoder form "" with
  | Error "ReWeb.Form.decoder: could not find key id" -> true
  | _ -> false

let%test _ =
  let fields { id; name } = ["id", string_of_int id; "name", name] in
  encode fields { id = 1; name = "Bob Roberts" } = "id=1&name=Bob%20Roberts"

let%test "ensure - error on validation fail" =
  match decoder form "id=1&name=" with
  | Error "ReWeb.Form.Field.ensure: name" -> true
  | _ -> false

