open ReWeb;

let notFound = _ =>
  "<h1>Not Found</h1>" |> Response.html(~status=`Not_found) |> Lwt.return;

let hello = _ => "Hello, World!" |> Response.text |> Lwt.return;

let getHeader = (name, request) =>
  switch (Request.header(name, request)) {
  | Some(value) =>
    value
    |> Printf.sprintf({|<h1>GET /header/:name</h1>
<p>%s: %s</p>|}, name)
    |> Response.html
    |> Lwt.return
  | None => notFound(request)
  };

let echoBody = request =>
  request
  |> Request.body
  |> Request.context
  |> Response.make(
       ~status=`OK,
       ~headers=
         ReWeb.Headers.of_list([
           ("content-type", "application/octet-stream"),
           ("connection", "close"),
         ]),
     )
  |> Lwt.return;

let server =
  fun
  | (`GET, ["hello"]) => hello
  | (`GET, ["header", name]) => getHeader(name)
  | (`POST, ["body"]) => echoBody
  | _ => notFound;

let () = server |> Server.serve |> Lwt_main.run;
