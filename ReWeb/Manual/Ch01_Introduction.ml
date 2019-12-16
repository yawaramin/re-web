(** ReWeb is a web framework for ReasonML. It is meant to enable web
    programming in a simple, functional (declarative) style. This style
    is inspired by the paper
    {{: https://monkey.org/~marius/funsrv.pdf} 'Your Server as a Function'}
    by Marius Eriksen. The fundamental concept of ReWeb is:

    {[request => promise of response]}

    Like other libraries inspired by this style, ReWeb aims to model the
    web's request-response paradigm with types that represent the request,
    the response, and the asynchronous nature of the response (hence
    'promise of response').

    Concretely, we call the [request => promise of response] type a
    {i service}, and a pairing of HTTP method (e.g. [`GET]) and path
    components (e.g. [["api"]] to represent [/api]) a {i route}. A ReWeb
    server is a single function that takes a route as input, and returns
    a service. E.g.:

    {[open ReWeb;

      let helloService = _request => Lwt.return(Response.text("Hello"));
      let server = _route => helloService;
      let () = Lwt_main.run(Server.serve(server));]}

    [Lwt.return] returns a fulfilled promise containing its argument, and
    [Lwt_main.run] starts Lwt's main event loop which runs promises.

    You can match routes more precisely:

    {[let notFoundService = _ =>
        Lwt.return(Response.text(~status=`Not_found, "Not found"));

      let server = fun
        | (`GET, ["hello"]) => helloService
        | _ => notFoundService;]}

    This server will respond with [hello] specifically at the [/hello]
    endpoint, and a 404 response at any other endpoint.

    See {!module:ReWeb.Server} for more details on servers. *)
