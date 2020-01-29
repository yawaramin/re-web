module Cache = Cache.Ephemeral(Cache.IntKey)

type 'a t = ('a Lwt_stream.t * ('a option -> unit)) Cache.t

(* A pair of (subscription key, topic) *)
type 'a subscription = int * 'a t

let make = Cache.make

let publish topic ~msg =
  Cache.iter topic ~f:(fun _ (_, push) -> push (Some msg))

let pull (key, topic) ~timeout =
  let open Let.Lwt in
  let* stream, _ = Cache.find topic ~key in
  Lwt.pick [
    Lwt_stream.get stream;
    timeout |> Lwt_unix.sleep |> Lwt.map @@ fun () -> None;
  ]

let make_key () =
  Random.self_init ();
  Random.bits ()

let subscribe topic =
  let stream_push = Lwt_stream.create () in
  let key = make_key () in
  let open Let.Lwt in
  let+ () = Cache.add topic ~key stream_push in
  key, topic

