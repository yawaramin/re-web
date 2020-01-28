module Make(Msg : sig type t end) : sig
  type subscription
  type t

  val close : t -> unit Lwt.t
  val make : unit -> t
  val publish : t -> msg:Msg.t -> unit Lwt.t
  val stream : subscription -> Msg.t Lwt_stream.t
  val subscribe : t -> subscription Lwt.t
  val unsubscribe : subscription -> unit Lwt.t
end
(** [Make(Msg)] is a module for topics that can handle messages of type
    [Msg.t]. *)

