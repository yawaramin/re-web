type chunk = {off : int; len : int; bigstring : Bigstringaf.t}
(** A single chunk of a multipart body. *)

type t = Single of Bigstringaf.t | Multi of chunk Lwt_stream.t
(**)
(** Request or response body. *)
