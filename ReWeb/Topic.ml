type key = Key of int

module Cache = Cache.Ephemeral(struct
  type t = key
  let equal (Key k1) (Key k2) = k1 = k2
  let hash = Hashtbl.seeded_hash
end)

type 'a t = ('a Lwt_stream.t * ('a option -> unit)) Cache.t

(* A pair of (subscription key, topic) *)
type 'a subscription = key * 'a t

let make = Cache.make

let num_subscribers = Cache.length

let publish topic ~msg =
  Cache.iter topic ~f:(fun _ (_, push) -> push (Some msg))

let publish_from (Key key, topic) ~msg =
  Cache.iter topic ~f:(fun (Key cache_key) (_, push) ->
    if key <> cache_key then push (Some msg))

let pull (key, topic) ~timeout =
  let open Lwt.Syntax in
  let* stream, _ = Cache.find topic ~key in
  Lwt.pick [
    Lwt_stream.get stream;
    timeout |> Lwt_unix.sleep |> Lwt.map @@ fun () -> None;
  ]

let () = Random.self_init ()

let subscribe topic =
  let stream_push = Lwt_stream.create () in
  let key = Key (Random.bits ()) in
  let open Lwt.Syntax in
  let+ () = Cache.add topic ~key stream_push in
  key, topic

