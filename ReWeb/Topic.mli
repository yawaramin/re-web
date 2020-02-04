type 'a t
(** A topic for messages of type ['a]. *)

type 'a subscription
(** A subscription to a topic of type ['a]. *)

val make : unit -> _ t
(** [make()] is a new topic. Typically you will create these at a scope
    that can pass them to any parts of the application that need them. *)

val num_subscribers : 'a t -> int Lwt.t
(** [num_subscribers(topic)] is a count of the subscribers of the given
    [topic]. *)

val publish : 'a t -> msg:'a -> unit Lwt.t
(** [publish(topic, ~msg)] publishes [msg] onto the [topic]. This
    broadcasts the [msg] to all subscribers of the [topic]. *)

val publish_from : 'a subscription -> msg:'a -> unit Lwt.t
(** [publish_from(subscription, ~msg)] publishes [msg] to the topic that
    [subscription] subscribes to, ensuring the message is sent to all
    subscribers {i except} the sender [subscription]. *)

val pull : 'a subscription -> timeout:float -> 'a option Lwt.t
(** [pull(subscription, ~timeout)] is a message from the topic
    subscribed to by [subscription] if there is one within the
    [timeout] (in seconds); else [None]. *)

val subscribe : 'a t -> 'a subscription Lwt.t
(** [subscribe(topic)] is a subscription to the [topic]. Note that
    subscriptions automatically get unsubscribed as soon as the
    [subscription] key goes out of scope. *)

