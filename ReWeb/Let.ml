module Option = struct
  let (let*) = Option.bind
  let (let+) option f = Option.map f option
end

module Result = struct
  let (let*) result f = match result with
    | Ok value -> f value
    | Error e -> Error e

  let (let+) result f = match result with
    | Ok value -> Ok (f value)
    | Error e -> Error e
end

module Lwt = struct
  let (let*) = Lwt.bind
  let (let+) lwt f = Lwt.map f lwt
end

