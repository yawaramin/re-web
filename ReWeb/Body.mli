(** Enables conversions between client and server request/response
    bodies. *)

type chunk = Bigstringaf.t Httpaf.IOVec.t

type t = private
| Bigstring of Bigstringaf.t
| Chunks of chunk Lwt_stream.t
| Piaf of Piaf.Body.t
| String of string (**)
(** Request or response body. *)

val make_chunk : ?len:int -> Bigstringaf.t -> chunk
val of_bigstring : Bigstringaf.t -> t
val of_piaf : Piaf.Body.t -> t
val of_stream : chunk Lwt_stream.t -> t
val of_string : string -> t
val to_json : t -> (Yojson.Safe.t, string) Lwt_result.t
val to_piaf : t -> Piaf.Body.t
val to_stream : t -> chunk Lwt_stream.t
val to_string : t -> string Lwt.t

