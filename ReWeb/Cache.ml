module type S = sig
  type key
  module Table : Hashtbl.SeededS with type key = key
  type 'a t

  val access : 'a t -> ('a Table.t -> 'b) -> 'b Lwt.t
  val add : 'a t -> key:key -> 'a -> unit Lwt.t
  val find_opt : 'a t -> key:key -> 'a option Lwt.t
  val make : unit -> 'a t
  val mem : 'a t -> key:key -> bool Lwt.t
  val remove : 'a t -> key:key -> unit Lwt.t
  val reset : 'a t -> unit Lwt.t
end

module InMemory(Key : Hashtbl.SeededHashedType) = struct
  module Table = Hashtbl.MakeSeeded(Key)

  type key = Key.t
  type 'a t = 'a Table.t * Lwt_mutex.t

  let make () = Table.create ~random:true 32, Lwt_mutex.create ()

  let access (table, lock) f = Lwt_mutex.with_lock lock @@ fun () ->
    table |> f |> Lwt.return

  let add t ~key value = access t @@ fun table ->
    Table.add table key value

  let find_opt t ~key = access t @@ fun table ->
    Table.find_opt table key

  let mem t ~key = access t @@ fun table -> Table.mem table key
  let remove t ~key = access t @@ fun table -> Table.remove table key
  let reset t = access t Table.reset
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

