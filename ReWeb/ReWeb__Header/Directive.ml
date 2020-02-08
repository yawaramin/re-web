let bool ~name value = if value then "; " ^ name else ""

let string ~name value =
  Option.fold ~none:"" ~some:((^) ("; " ^ name ^ "=")) value

let int ~name value = string ~name @@ Option.map string_of_int value

