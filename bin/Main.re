open ReWeb;

let notFound =
  Response.("<h1>Not Found</h1>" |> html(~status=`Not_found) |> return);

let server =
  fun
  | (`GET, ["hello"]) => Response.("Hello, World!" |> text |> return)
  | _ => notFound;

let () = server |> Server.serve |> Lwt_main.run;
