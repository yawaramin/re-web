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
      [table] contained in the [cache] and can do anything with it.
      Usually you will use this to read or write the cache. *)

  val make : unit -> 'a t
  (** [make()] allocates a new cache value. *)
end

module InMemory(Key : Hashtbl.SeededHashedType) : S with type key = Key.t
(** Create a module to manage a concurrent in-memory cache. *)

module IntKey : Hashtbl.SeededHashedType with type t = int
(** Use this to create a cache module for caches with [int] keys. *)

module StringKey : Hashtbl.SeededHashedType with type t = string
(** Use this to create a cache module for caches with [string] keys. *)

