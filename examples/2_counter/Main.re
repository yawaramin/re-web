open ReWeb;

/* Create a mutable let binding */
let count = ref(0);

/* Grab the value from count and send it as a text response */
let getCount = _ => count^ |> string_of_int |> Response.of_text |> Lwt.return;

/* Increment the count and then respond with a status of OK */
let increment = _ => {
  count := count^ + 1;
  `OK |> Response.of_status |> Lwt.return;
};

let notFound = _ => `Not_found |> Response.of_status |> Lwt.return;

/* Add the POST route so users can increment the count */
let routes =
  fun
  | (`GET, ["count"]) => getCount
  | (`POST, ["increment"]) => increment
  | _ => notFound;

let () = routes |> Server.serve |> Lwt_main.run;
