type t = All | One of string

let to_string = function
  | All -> "*"
  | One origin -> origin

