open ReWeb;

// Couple of helpers

let tickToJson = Printf.sprintf({|{"data": {"tick": "%s"}}|});
let errorToJson = Printf.sprintf({|{"error": "%s"}|});

// Handler of the WebSocket service
let rec handler = (pull, push) => {
  open Lwt.Syntax;
  let* message = pull(3.);

  switch (message) {
  // Shut down the WS if the client actually sends a message
  | Ok(_) =>
    "this WebSocket does not accept incoming messages"
    |> errorToJson
    |> push
    |> Lwt.return

  // Shut down if client wants to
  | Error(`Connection_close) => Lwt.return_unit

  // Otherwise carry on
  | _ =>
    let* response = Client.New.get("http://localhost:8080/hello");

    switch (response) {
    | Ok(response) =>
      let* tick = response |> Response.body |> Body.to_string;

      // Put the tick response in a JSON data structure and send it
      tick |> tickToJson |> push;
      handler(pull, push);
    | Error(message) =>
      message |> errorToJson |> push;
      handler(pull, push);
    }
  };
};

/** [service(request)] is a service that starts a WebSocket that queries
    the {i same} server (i.e. the one defined in [Main.re]) to get data
    every 3 seconds and sends it to the client. Of course you can send
    requests to {i any} server but this is just a cool demo :-) */
let service = _ => handler |> Response.of_websocket |> Lwt.return;
