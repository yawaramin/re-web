type privately = {
  must_revalidate : bool option;
  max_age : int option;
}

type publicly = {
  no_transform : bool option;
  proxy_revalidate : bool option;
  s_maxage : int option;
}

type t =
| No_store
| No_cache
| Private of privately
| Public of privately * publicly

let private_ ?must_revalidate ?max_age () = Private {
  must_revalidate;
  max_age;
}

let public
  ?must_revalidate
  ?max_age
  ?no_transform
  ?proxy_revalidate
  ?s_maxage
  () =
  Public (
    { must_revalidate; max_age },
    { no_transform; proxy_revalidate; s_maxage }
  )

let commalist list = match List.filter ((<>) "") list with
  | [] -> ""
  | directives -> "," ^ String.concat "," directives

let privately_to_string { must_revalidate; max_age } = commalist [
  if Option.value ~default:false must_revalidate
  then "must-revalidate"
  else "";

  max_age
  |> Option.map (fun int -> int |> string_of_int |> ((^) "max-age="))
  |> Option.value ~default:"";
]

let publicly_to_string { no_transform; proxy_revalidate; s_maxage } =
  commalist [
    if Option.value ~default:false no_transform
    then "no-transform"
    else "";

    if Option.value ~default:false proxy_revalidate
    then "proxy-revalidate"
    else "";

    s_maxage
    |> Option.map (fun int -> int |> string_of_int |> ((^) "s-maxage="))
    |> Option.value ~default:"";
  ]

let to_string = function
  | No_store -> "no-store"
  | No_cache -> "no-cache"
  | Private privately -> "private" ^ privately_to_string privately
  | Public (privately, publicly) ->
    "public" ^ privately_to_string privately ^ publicly_to_string publicly

