(** The cache module here uses Lwt to ensure that caches are accessed
    serially to prevent inconsistent data accesses. *)

module type S = sig
  type key
  module Table : Hashtbl.SeededS with type key = key
  type 'a t

  val access : 'a t -> ('a Table.t -> 'b) -> 'b Lwt.t
  (** [access(cache, f)] runs the function [f] on the hash table
      contents of the [cache], returning the result value. It can be
      used to both read from and write to the cache.

      [f(table)] is a callback which has locked access to the hash
      [table] contained in the [cache] and can do anything with it,
      including multiple operations like checking if the cache contains
      a key, then adding it or not.

      Since this does lock the cache, it is preferable to not do
      long-running operations here, and to finish and unlock as quickly
      as possible. *)

  val add : 'a t -> key:key -> 'a -> unit Lwt.t
  val find : 'a t -> key:key -> 'a Lwt.t
  val find_opt : 'a t -> key:key -> 'a option Lwt.t
  val iter : 'a t -> f:(key -> 'a -> unit) -> unit Lwt.t
  val length : 'a t -> int Lwt.t

  val make : unit -> 'a t
  (** [make()] allocates a new cache value. *)

  val mem : 'a t -> key:key -> bool Lwt.t
  val remove : 'a t -> key:key -> unit Lwt.t
  val reset : 'a t -> unit Lwt.t
end
(** Aside from [make] and [access], the rest of the functions in this
    interface are similar to the ones in [Hashtbl], so you can use those
    as a reference. *)

module Ephemeral(Key : Hashtbl.SeededHashedType) : S with type key = Key.t
(** [Ephemeral(Key)] is a module that manages an ephemeral concurrent
    cache. An ephemeral cache is one whose bindings are deleted as soon
    as its keys go out of scope.

    {i Note} that this module overrides [length] to count {i live} items
    only. That is, only items whose keys are referred to by some value. *)

module InMemory(Key : Hashtbl.SeededHashedType) : S with type key = Key.t
(** [InMemory(Key)] is a module that manages a concurrent in-memory
    cache. *)

module IntKey : Hashtbl.SeededHashedType with type t = int
(** [IntKey] is a module that can be used to create a cache with [int]
    keys. *)

module Make(T : Hashtbl.SeededS) : S with type key = T.key
(** [Make(T)] is a module that manages a concurrent cache with the
    persistence characteristics offered by the [Table] module. *)

module StringKey : Hashtbl.SeededHashedType with type t = string
(** [StringKey] is a module that can be used to create a cache with
    [string] keys. *)

