open Alcotest

module Topic = ReWeb.Topic

let msg = 0
let timeout = 1.
let received_msg = option int

let s = "ReWeb.Topic", [
  Alcotest_lwt.test_case "make, subscribe, publish, pull" `Quick begin fun _ () ->
    let topic = Topic.make () in
    let open Lwt.Syntax in

    (* First 'we' subscribe to the topic *)
    let* subscription = Topic.subscribe topic in

    (* Then 'someone' publishes something to the topic *)
    let* () = Topic.publish topic ~msg in

    (* While the topic is streaming out data, check we got what we
       expected *)
    let+ msg_option = Topic.pull subscription ~timeout in
    check received_msg "" (Some msg) msg_option
  end;

  Alcotest_lwt.test_case "subscribe - subscriptions are automatically unsubscribed" `Quick begin fun _ () ->
    let topic = Topic.make () in
    let open Lwt.Syntax in
    let* num = Topic.num_subscribers topic in
    check int "before any subscriptions" 0 num;
    let subscribe () =
      let* subscription = Topic.subscribe topic in
      let+ num = Topic.num_subscribers topic in
      check int "after subscribing" 1 num
    in
    let* () = subscribe () in
    Gc.full_major ();
    let+ num = Topic.num_subscribers topic in
    check int "after subscription goes out of scope" 0 num
  end;

  Alcotest_lwt.test_case "publish_from - publishes to subscribers other than sender" `Quick begin fun _ () ->
    let topic = Topic.make () in
    let open Lwt.Syntax in
    let* sender_subscription = Topic.subscribe topic in
    let* receiver_subscription = Topic.subscribe topic in
    let* () = Topic.publish_from sender_subscription ~msg in
    let* sender_received = Topic.pull sender_subscription ~timeout in
    check received_msg "sender did not receive message" None sender_received;
    let+ receiver_received = Topic.pull receiver_subscription ~timeout in
    check received_msg "receiver received message" (Some msg) receiver_received
  end;
]

