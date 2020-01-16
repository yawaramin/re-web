type t = {
  max_age : int; (** In seconds *)
  include_subdomains : bool;
  preload : bool;
}

let make ?(include_subdomains=true) ?(preload=true) max_age = {
  max_age;
  include_subdomains;
  preload;
}

let to_header { max_age; include_subdomains; preload } =
  let open Directive in
  "strict-transport-security",
  "max-age="
  ^ string_of_int max_age
  ^ bool ~name:"includeSubDomains" include_subdomains
  ^ bool ~name:"preload" preload

