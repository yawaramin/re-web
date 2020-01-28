module Make(Msg : sig type t end) = struct
  module Cache = Cache.InMemory(Cache.IntKey)
  type t = (Msg.t option -> unit) Cache.t

  type subscription = {
    key : int;
    topic : t;
    stream : Msg.t Lwt_stream.t;
  }

  let make = Cache.make

  let publish topic ~msg =
    Cache.iter topic ~f:(fun _ push -> push (Some msg))

  let make_key () =
    Random.self_init ();
    Random.bits ()

  let subscribe topic =
    let stream, push = Lwt_stream.create () in
    let key = make_key () in
    let open Let.Lwt in
    let+ () = Cache.add topic ~key push in
    { key; topic; stream }

  let stream { stream; _ } = stream

  let unsubscribe { topic; key; _ } = Cache.access topic begin fun table ->
    (* Close the stream, then remove its push function from the cache. *)
    Cache.Table.find table key None;
    Cache.Table.remove table key
  end

  let close topic = Cache.access topic begin fun table ->
    Cache.Table.iter (fun _ push -> push None) table;
    Cache.Table.reset table
  end
end

