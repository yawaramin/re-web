open ReWeb.Form

type user = { id : int; name : string }

let user id name = { id; name }

let form = make
  Field.[int "id"; "name" |> string |> ensure ((<>) "")]
  user

let%test "decoder - decode correctly" =
  decoder form "id=1&name=Bob" = Ok { id = 1; name = "Bob" }

let%test "decoder - error on bad input" =
  decoder form "" = Error "ReWeb.Form.decoder: could not find key id"

let%test _ =
  let fields { id; name } = ["id", string_of_int id; "name", name] in
  encode fields { id = 1; name = "Bob Roberts" } = "id=1&name=Bob%20Roberts"

let%test "ensure - error on validation fail" =
  decoder form "id=1&name=" = Error "ReWeb.Form.Field.ensure: name"

