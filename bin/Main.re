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

let server =
  fun
  | (`GET, ["hello"]) => hello
  | (`GET, ["header", name]) => getHeader(name)
  | _ => notFound;

let () = server |> Server.serve |> Lwt_main.run;
