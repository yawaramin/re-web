type t =
| Single of Bigstringaf.t
| Multi of Bigstringaf.t Httpaf.IOVec.t Lwt_stream.t (**)
(** Request or response body. *)
