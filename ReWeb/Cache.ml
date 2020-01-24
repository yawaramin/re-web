module type S = sig
  type key
  module Table : Hashtbl.SeededS with type key = key
  type 'a t

  val access : 'a t -> ('a Table.t -> 'b) -> 'b Lwt.t
  val make : unit -> 'a t
end

module InMemory(Key : Hashtbl.SeededHashedType) = struct
  module Table = Hashtbl.MakeSeeded(Key)

  type key = Key.t
  type 'a t = 'a Table.t * Lwt_mutex.t

  let make () = Table.create ~random:true 32, Lwt_mutex.create ()

  let access (table, lock) f = Lwt_mutex.with_lock lock @@ fun () ->
    table |> f |> Lwt.return
end

module SimpleKey = struct
  let equal = (=)
  let hash = Hashtbl.seeded_hash
end

module IntKey = struct
  include SimpleKey
  type t = int
end

module StringKey = struct
  include SimpleKey
  type t = string
end

