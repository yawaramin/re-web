open ReWeb;

let notFound = _ =>
  "<h1>Not Found</h1>" |> Response.html(~status=`Not_found) |> Lwt.return;

let hello = _ => "Hello, World!" |> Response.text |> Lwt.return;

let getHeader = (name, request) =>
  switch (Request.header(name, request)) {
  | Some(value) =>
    value
    |> Printf.sprintf({|<h1>GET /header/%s</h1>
<p>%s</p>|}, name)
    |> Response.html
    |> Lwt.return
  | None => notFound(request)
  };

let getStatic = (fileName, _) =>
  fileName
  |> String.concat("/")
  |> (++)("/")
  |> Response.static(~content_type="text/plain");

let echoBody = request =>
  request
  |> Request.with_body
  |> Request.context
  |> Response.make(
       ~status=`OK,
       ~headers=
         Headers.of_list([
           ("content-type", "application/octet-stream"),
           ("connection", "close"),
         ]),
     )
  |> Lwt.return;

let server =
  fun
  | (`GET, ["hello"]) => hello
  | (`GET, ["header", name]) => getHeader(name)
  | (`GET, ["static", ...fileName]) => getStatic(fileName)
  | (`POST, ["body"]) => echoBody
  | _ => notFound;

let () = server |> Server.serve |> Lwt_main.run;
