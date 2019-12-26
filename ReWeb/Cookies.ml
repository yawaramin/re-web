type t = (string * string) list
(** A cookie [Set-Cookie: id=1] is represented as: [[("id", "1")]]. *)

let header_to_cookie value = match String.split_on_char '=' value with
  | [name; value] -> Some (name, value)
  | _ -> None

let of_headers values = values
  |> List.map header_to_cookie
  |> List.filter Option.is_some
  |> List.map @@ function
    | Some cookie -> cookie
    | None ->
      failwith "This case should not be reached because Nones are filtered out beforehand"

let to_header (name, value) = "cookie", name ^ "=" ^ value
let to_headers cookies = List.map to_header cookies

