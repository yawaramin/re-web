type t = All | One of string

let to_header t = "access-control-allow-origin", match t with
  | All -> "*"
  | One origin -> origin

