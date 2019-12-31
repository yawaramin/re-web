open ReWeb;

// Couple of helpers

let tickToJson = Printf.sprintf({|{"data": {"tick": "%s"}}|});
let errorToJson = Printf.sprintf({|{"error": "%s"}|});

/** [service(request)] is a service that starts a WebSocket that queries
    the {i same} server (i.e. the one defined in [Main.re]) to get data
    every 3 seconds and sends it to the client. Of course you can send
    requests to {i any} server but this is just a cool demo :-) */
let service = _ => {
  let rec handler = (pull, push) => {
    // Pull any data the client might have sent, timeout in 3s
    let%lwt message = pull(3.);

    switch (message) {
    // Shut down the WS if the client actually sends a message
    | Some(_) =>
      "this WebSocket does not accept incoming messages"
      |> errorToJson
      |> push
      |> Lwt.return

    // Otherwise carry on
    | None =>
      let%lwt response = Client.New.get("http://localhost:8080/hello");

      let%lwt () =
        switch (response) {
        | Ok(response) =>
          let%lwt tick = response |> Response.body |> Body.to_string;

          // Put the tick response in a JSON data structure and send it
          tick |> tickToJson |> push |> Lwt.return;

        | Error(message) => message |> errorToJson |> push |> Lwt.return
        };

      handler(pull, push);
    };
  };

  handler |> Response.of_websocket |> Lwt.return;
};
