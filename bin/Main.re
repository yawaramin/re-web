open ReWeb;

let hello = _ => Response.("Hello, World!" |> text |> Lwt.return);

let notFound = _ =>
  Response.("<h1>Not Found</h1>" |> html(~status=`Not_found) |> Lwt.return);

let server =
  fun
  | (`GET, ["hello"]) => hello
  | _ => notFound;

let () = server |> Server.serve |> Lwt_main.run;
