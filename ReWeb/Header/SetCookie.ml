type same_site = None | Strict | Lax
type t = string * string

let make
  ?max_age
  ?(secure=Config.Default.secure)
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
  let open Directive in
  name,
  value
  ^ int ~name:"Max-Age" max_age
  ^ bool ~name:"Secure" secure
  ^ bool ~name:"HttpOnly" http_only
  ^ string ~name:"Domain" domain
  ^ string ~name:"Path" path
  ^ "; SameSite="
  ^ same_site

let name = fst
let to_header (name, value) = "set-cookie", name ^ "=" ^ value

let of_header value = match String.split_on_char '=' value with
  | []
  | [_] -> Option.None
  | name :: value -> Some (name, String.concat "=" value)

let value = snd

