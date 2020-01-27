module Make(Msg : sig type t end) : sig
  type subscription
  type t

  val make : unit -> t
  val publish : t -> Msg.t -> unit Lwt.t
  val subscribe : t -> subscription Lwt.t
  val unsubscribe : subscription -> unit Lwt.t
end
(** [Make(Msg)] is a module for topics that can handle messages of type
    [Msg.t]. *)

