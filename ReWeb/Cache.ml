module type S = sig
  type key
  module Table : Hashtbl.SeededS with type key = key
  type 'a t

  val access : 'a t -> ('a Table.t -> 'b) -> 'b Lwt.t
  val add : 'a t -> key:key -> 'a -> unit Lwt.t
  val find : 'a t -> key:key -> 'a Lwt.t
  val find_opt : 'a t -> key:key -> 'a option Lwt.t
  val iter : 'a t -> f:(key -> 'a -> unit) -> unit Lwt.t
  val length : 'a t -> int Lwt.t
  val make : unit -> 'a t
  val mem : 'a t -> key:key -> bool Lwt.t
  val remove : 'a t -> key:key -> unit Lwt.t
  val reset : 'a t -> unit Lwt.t
end

module Make(T : Hashtbl.SeededS) = struct
  module Table = T
  type key = Table.key
  type 'a t = 'a Table.t * Lwt_mutex.t

  let make () = Table.create ~random:true 32, Lwt_mutex.create ()

  let access (table, lock) f = Lwt_mutex.with_lock lock @@ fun () ->
    table |> f |> Lwt.return

  let add t ~key value = access t @@ fun table ->
    Table.add table key value

  let find t ~key = access t @@ fun table -> Table.find table key

  let find_opt t ~key = access t @@ fun table ->
    Table.find_opt table key

  let iter t ~f = access t @@ fun table -> Table.iter f table
  let length t = access t Table.length
  let mem t ~key = access t @@ fun table -> Table.mem table key
  let remove t ~key = access t @@ fun table -> Table.remove table key
  let reset t = access t Table.reset
end

module Ephemeral(Key : Hashtbl.SeededHashedType) = struct
  module EphemeralHashtbl = Ephemeron.K1.MakeSeeded(Key)
  include Make(EphemeralHashtbl)

  let () = Random.self_init ()

  let find t ~key = access t begin fun table ->
    (* Instead of keeping a counter and cleaning exactly every 8 times,
       we probabilistically clean 1/8 times. *)
    if Random.int 8 = 0 then begin EphemeralHashtbl.clean table end;
    EphemeralHashtbl.find table key
  end

  let length t = access t begin fun table ->
    EphemeralHashtbl.clean table;
    EphemeralHashtbl.length table
  end
end

module InMemory(Key : Hashtbl.SeededHashedType) =
  Make(Hashtbl.MakeSeeded(Key))

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

