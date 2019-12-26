type chunk = Bigstringaf.t Httpaf.IOVec.t

type t =
| Single of Bigstringaf.t
| Multi of chunk Lwt_stream.t
| Piaf of Piaf.Body.t (**)
(** Request or response body. *)

val make_chunk : ?len:int -> Bigstringaf.t -> chunk
val of_bigstring : Bigstringaf.t -> t
val of_stream : chunk Lwt_stream.t -> t
val of_string : string -> t
val to_json : t -> (Ezjsonm.t, string) Lwt_result.t
val to_piaf : t -> Piaf.Body.t
val to_string : t -> string Lwt.t

