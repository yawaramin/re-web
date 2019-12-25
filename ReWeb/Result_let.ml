let (let*) result f = match result with
  | Ok value -> f value
  | Error e -> Error e

let (let+) result f = match result with
  | Ok value -> Ok (f value)
  | Error e -> Error e

