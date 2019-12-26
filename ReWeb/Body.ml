module H = Httpaf

type chunk = Bigstringaf.t H.IOVec.t

type t =
| Bigstring of Bigstringaf.t
| Chunks of chunk Lwt_stream.t
| Piaf of Piaf.Body.t
| String of string

let of_bigstring bigstring = Bigstring bigstring
let of_piaf body = Piaf body
let of_stream chunks = Chunks chunks
let of_string string = String string

let make_chunk ?len buffer =
  let len = Option.value len ~default:(Bigstringaf.length buffer) in
  { H.IOVec.off = 0; len; buffer }

let to_piaf = function
  | Bigstring bigstring -> Piaf.Body.of_bigstring bigstring
  | Chunks chunks -> Piaf.Body.of_stream chunks
  | Piaf body -> body
  | String string -> Piaf.Body.of_string string

let to_string = function
  | Bigstring bigstring ->
    bigstring |> Bigstringaf.to_string |> Lwt.return
  | Chunks chunks ->
    chunks |> Piaf.Body.of_stream |> Piaf.Body.to_string
  | Piaf body -> Piaf.Body.to_string body
  | String string -> Lwt.return string

let to_json body =
  let open Let.Lwt in
  let+ body_string = to_string body in
  match Ezjsonm.from_string body_string with
  | body -> Ok body
  | exception Ezjsonm.Parse_error (_, string) ->
    Error ("ReWeb.Body.to_json: " ^ string)
  | exception Assert_failure (_, _, _) ->
    Error "ReWeb.Filter.body_json: not a JSON document"

