open Reweb

type t = { username : string; password : string }

let form =
  let open Form in
  make
    Field.[
      string "username";
      (* Form validation will fail if the password is 'password' *)
      "password" |> string |> ensure (( <> ) "password");
    ]
    @@ fun username password -> { username; password }
