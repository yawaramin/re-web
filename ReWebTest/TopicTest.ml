open Alcotest
open Alcotest

module Let = ReWeb__Let
module Topic = ReWeb.Topic.Make(struct type t = int end)

let s = "ReWeb.Topic", [
  Alcotest_lwt.test_case "make, subscribe, publish, stream, close" `Quick begin fun _ () ->
    let msg = 0 in
    let topic = Topic.make () in
    let open Let.Lwt in

    (* First 'we' subscribe to the topic *)
    let* subscription = Topic.subscribe topic in

    (* Then 'someone' publishes something to the topic *)
    let* () = Topic.publish topic ~msg in

    (* While the topic is streaming out data, check we got what we
       expected *)
    subscription |> Topic.stream |> Lwt_stream.iter (check int "" msg) |> ignore;

    (* Close the topic to close the stream *)
    Topic.close topic
  end;

  Alcotest_lwt.test_case "unsubscribe - close stream" `Quick begin fun switch () ->
    let topic = Topic.make () in
    let close () = Topic.close topic in
    Lwt_switch.add_hook (Some switch) close;

    let open Let.Lwt in
    let* subscription = Topic.subscribe topic in
    let* () = Topic.unsubscribe subscription in
    let+ () = Topic.publish topic 0 in
    subscription
    |> Topic.stream
    |> Lwt_stream.is_closed
    |> check bool "" true
  end;
]

