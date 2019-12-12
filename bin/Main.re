open ReWeb;

let server =
  fun
  | (`GET, ["hello"]) => Response.("Hello, World!" |> string |> return)
  | _ => Response.("Not found" |> string(~status=`Not_found) |> return);

let () = server |> Server.serve |> Lwt_main.run;
