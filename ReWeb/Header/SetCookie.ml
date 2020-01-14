type same_site = None | Strict | Lax
type t = string * string

let bool ~name value = if value then "; " ^ name else ""
let string ~name value =
  Option.fold ~none:"" ~some:((^) ("; " ^ name ^ "=")) value
let int ~name value = string ~name @@ Option.map string_of_int value

let make
  ?max_age
  ?(secure=Config.Default.secure_cookies)
  ?(http_only=true)
  ?domain
  ?path
  ?(same_site=Lax)
  ~name
  value =
  let same_site = match same_site with
    | None -> "None"
    | Strict -> "Strict"
    | Lax -> "Lax"
  in
  "set-cookie",
  name
  ^ "="
  ^ value
  ^ int ~name:"Max-Age" max_age
  ^ bool ~name:"Secure" secure
  ^ bool ~name:"HttpOnly" http_only
  ^ string ~name:"Domain" domain
  ^ string ~name:"Path" path
  ^ "; SameSite="
  ^ same_site

let name = fst
let to_header cookie = cookie

let of_header value = match String.split_on_char '=' value with
  | [name; value] -> Some (name, value)
  | _ -> None

let value = snd

