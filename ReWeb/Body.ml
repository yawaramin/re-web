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

let to_stream = function
  | Bigstring bigstring -> Lwt_stream.of_list [make_chunk bigstring]
  | Chunks chunks -> chunks
  | Piaf body ->
    body |> Piaf.Body.to_stream |> Lwt_stream.map make_chunk
  | String string ->
    let len = String.length string in
    Lwt_stream.of_list [
      string
      |> Bigstringaf.of_string ~off:0 ~len
      |> make_chunk ~len
    ]

let to_string = function
  | Bigstring bigstring ->
    bigstring |> Bigstringaf.to_string |> Lwt.return
  | Chunks chunks ->
    chunks |> Piaf.Body.of_stream |> Piaf.Body.to_string
  | Piaf body -> Piaf.Body.to_string body
  | String string -> Lwt.return string

let to_json body =
  let open Lwt.Syntax in
  let+ body_string = to_string body in
  match Yojson.Safe.from_string body_string with
  | body -> Ok body
  | exception Yojson.Json_error string ->
    Error ("ReWeb.Body.to_json: " ^ string)

