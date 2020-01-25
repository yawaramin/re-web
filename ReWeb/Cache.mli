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
  val find_opt : 'a t -> key:key -> 'a option Lwt.t

  val make : unit -> 'a t
  (** [make()] allocates a new cache value. *)

  val mem : 'a t -> key:key -> bool Lwt.t
  val remove : 'a t -> key:key -> unit Lwt.t
  val reset : 'a t -> unit Lwt.t
end
(** Aside from [make] and [access], the rest of the functions in this
    interface are similar to the ones in [Hashtbl], so you can use those
    as a reference. *)

module InMemory(Key : Hashtbl.SeededHashedType) : S with type key = Key.t
(** Create a module to manage a concurrent in-memory cache. *)

module IntKey : Hashtbl.SeededHashedType with type t = int
(** Use this to create a cache module for caches with [int] keys. *)

module StringKey : Hashtbl.SeededHashedType with type t = string
(** Use this to create a cache module for caches with [string] keys. *)

