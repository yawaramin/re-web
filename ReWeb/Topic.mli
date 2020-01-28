module Make(Msg : sig type t end) : sig
  type subscription
  type t

  val close : t -> unit Lwt.t
  (** [close(topic)] closes an open topic. It has no effect on a closed
      topic. *)

  val make : unit -> t
  (** [make()] is a new topic. Typically you will create these at a
      scope that can pass them to any parts of the application that need
      them. *)

  val publish : t -> msg:Msg.t -> unit Lwt.t
  (** [publish(topic, ~msg)] publishes [msg] onto the [topic]. This
      broadcasts the [msg] to all subscribers of the [topic]. *)

  val stream : subscription -> Msg.t Lwt_stream.t
  (** [stream(subscription)] is a live stream of all messages published
      to the topic subscribed to with [subscription]. *)

  val subscribe : t -> subscription Lwt.t
  (** [subscribe(topic)] is a subscription to the [topic]. *)

  val unsubscribe : subscription -> unit Lwt.t
  (** [unsubscribe(subscription)] unsubscribes from the topic that was
      subscribed to with [subscription]. *)
end
(** [Make(Msg)] is a module for topics that can handle messages of type
    [Msg.t]. *)

