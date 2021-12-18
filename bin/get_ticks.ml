open ReWeb

(* Couple of helpers *)

let tick_to_json = Printf.sprintf {|{"data": {"tick": "%s"}}|}
let error_to_json = Printf.sprintf {|{"error": "%s"}|}

(* Handler of the WebSocket service *)
let rec handler pull push =
  let open Lwt.Syntax in
  let* message = pull 3. in
  match message with
  (* Shut down the WS if the client actually sends a message *)
  | Ok _ ->
    "this WebSocket does not accept incoming messages"
    |> error_to_json
    |> push
    |> Lwt.return
  (* Shut down if client wants to *)
  | Error `Connection_close ->
    Lwt.return_unit
  (* Otherwise carry on *)
  | _ ->
    let* response = Client.New.get "http://localhost:8080/hello" in
    match response with
    | Ok response ->
      let* result = response |> Response.body |> Piaf.Body.to_string in
      begin match result with
      | Ok tick ->
        (* Put the tick response in a JSON data structure and send it *)
        tick |> tick_to_json |> push;
        handler pull push
      | Error error ->
        error |> Piaf.Error.to_string |> error_to_json |> push;
        handler pull push
      end
    | Error message ->
      message |> error_to_json |> push;
      handler pull push

(** [service(request)] is a service that starts a WebSocket that queries
    the {i same} server (i.e. the one defined in [main.ml]) to get data
    every 3 seconds and sends it to the client. Of course you can send
    requests to {i any} server but this is just a cool demo :-) *)
let service _ = handler |> Response.of_websocket |> Lwt.return
