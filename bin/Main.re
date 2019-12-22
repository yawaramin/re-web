open ReWeb;

let notFound = _ =>
  {|<!doctype html>
<html>
  <head>
    <meta charset="utf-8">
    <title>Not Found</title>
  </head>
  <body>
    <h1>Not Found</h1>
  </body>
</html>|}
  |> Response.html(~status=`Not_found)
  |> Lwt.return;

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

let getLogin = _ =>
  View.login(~rememberMe=true) |> Response.render |> Lwt.return;

let getStatic = (fileName, _) =>
  fileName
  |> String.concat("/")
  |> (++)("/")
  |> Response.static(~content_type="text/plain");

let echoBody = request =>
  request
  |> Request.body
  |> Response.make(
       ~status=`OK,
       ~headers=
         Headers.of_list([
           ("content-type", "application/octet-stream"),
           ("connection", "close"),
         ]),
     )
  |> Lwt.return;

let exclaimBody = request =>
  request
  |> Request.body_string
  |> Lwt.map(string => Response.text(string ++ "!"));

let authHello = request => {
  let context = Request.context(request);

  context#password
  |> Printf.sprintf("Username = %s\nPassword = %s", context#username)
  |> Response.text
  |> Lwt.return;
};

let authServer =
  fun
  | (`GET, ["hello"]) => authHello
  | _ => notFound;

let server =
  fun
  | (`GET, ["hello"]) => hello
  | (`GET, ["header", name]) => getHeader(name)
  | (`GET, ["login"]) => getLogin
  | (`GET, ["static", ...fileName]) => getStatic(fileName)
  | (`POST, ["body"]) => echoBody
  | (`POST, ["body-bang"]) => exclaimBody
  | (meth, ["auth", ...path]) =>
    Filter.basic_auth @@ authServer @@ (meth, path)
  | _ => notFound;

let msie = Str.regexp(".*MSIE.*");

let rejectExplorer = (next, request) =>
  switch (Request.header("user-agent", request)) {
  | Some(ua) when Str.string_match(msie, ua, 0) =>
    "Please upgrade your browser"
    |> Response.text(~status=`Unauthorized)
    |> Lwt.return
  | _ => next(request)
  };

let server = route => rejectExplorer @@ server @@ route;
let () = server |> Server.serve |> Lwt_main.run;
