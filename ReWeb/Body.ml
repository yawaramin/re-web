module H = Httpaf

type t =
| Single of Bigstringaf.t
| Multi of Bigstringaf.t H.IOVec.t Lwt_stream.t
| Piaf of Piaf.Body.t (**)
(** Request or response body. *)

let make_chunk ?len buffer =
  let len = Option.value len ~default:(Bigstringaf.length buffer) in
  { H.IOVec.off = 0; len; buffer }

let to_piaf = function
  | Single bigstring ->
    let len = Bigstringaf.length bigstring in
    [make_chunk ~len bigstring]
    |> Lwt_stream.of_list
    |> Piaf.Body.of_stream ~length:(`Fixed (Int64.of_int len))
  | Multi stream -> Piaf.Body.of_stream stream
  | Piaf body -> body

let to_string = function
  | Single bigstring -> bigstring |> Bigstringaf.to_string |> Lwt.return
  | Multi stream -> stream |> Piaf.Body.of_stream |> Piaf.Body.to_string
  | Piaf body -> Piaf.Body.to_string body

let to_json body =
  let open Lwt_let in
  let+ body_string = to_string body in
  match Ezjsonm.from_string body_string with
  | body -> Ok body
  | exception Ezjsonm.Parse_error (_, string) ->
    Error ("ReWeb.Body.to_json: " ^ string)
  | exception Assert_failure (_, _, _) ->
    Error "ReWeb.Filter.body_json: not a JSON document"

