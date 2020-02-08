(** ReWeb is a web framework for ReasonML. It is meant to enable web
    programming in a simple, functional (declarative) style. This style
    is inspired by the paper
    {{: https://monkey.org/~marius/funsrv.pdf} 'Your Server as a Function'}
    by Marius Eriksen. The fundamental concept of ReWeb is:

    {[request => promise of response]}

    {1 Services}

    Like other libraries inspired by this style, ReWeb aims to model the
    web's request-response paradigm with types that represent the
    request, the response, and the asynchronous nature of the response
    (hence 'promise of response').

    Concretely, we call the [request => promise of response] type a
    {i service}, and a pairing of HTTP method (e.g. [`GET]) and path
    components (e.g. [["api"]] to represent [/api]) a {i route}. A ReWeb
    server is a single function that takes a route as input, and returns
    a service. E.g.:

    {[open ReWeb;

      let helloService = _request => Lwt.return(Response.of_text("Hello"));
      let server = _route => helloService;
      let () = Server.serve(server);]}

    [Lwt.return] returns a fulfilled promise containing its argument,
    and {!ReWeb.Server.serve} starts running the server.

    {1 Routes}

    You can match routes more precisely:

    {[let notFoundService = _ =>
        Lwt.return(Response.of_text(~status=`Not_found, "Not found"));

      let server = fun
        | (`GET, ["hello"]) => helloService
        | _ => notFoundService;]}

    This server will respond with [hello] specifically at the [/hello]
    endpoint, and a 404 response at any other endpoint.

    See {!module:ReWeb.Server} for more details on servers.

    {1 Filters}

    The final important top-level concept to understand is {i filters},
    which are service transformer functions. Filters are functions of
    type (roughly):

    {[service => service]}

    Filters are essentially like middleware in ExpressJS and other web
    frameworks; they plug in to the request pipeline and change requests
    or responses in certain ways. You can imagine it like a data flow:

    {[client =>
      request =>
      [filter1 => ... => filterN =>]
      service =>
      promise of response]}

    As you can tell, zero or more filters can be plugged into the
    pipeline before the service. By the time the service runs, the
    filters that ran before it might have performed authentication using
    the request's HTTP [Authorization] header, read the request body,
    safely decoded it from a web form into a strongly-typed value, and
    put the value in the request's 'context' (we will cover that in a
    later chapter). If any of those filters failed, typically they would
    short-circuit the pipeline and respond with a 400 Bad Request, 403
    Forbidden, or other appropriate response status.

    One of the key benefits of ReWeb filters is that they are type-safe.
    Specifically this means that their 'input context' and 'output
    context' types are exposed at the type level, and only filters and
    services which have compatible input context/output context types
    can plug together. Those that don't, will result in a compile error.

    So concretely this means that a service that tries to get the auth
    token and the decoded form body from the request context, will only
    compile if the filters which do those jobs were actually plugged in
    to the request pipeline before it.

    A lot of ReWeb's functionality comes from filters, ones that ship
    with ReWeb itself, or ones you write yourself, or even get from a
    third party. If you're wondering how to do something, chances are
    you can do it with a filter. Check {!Ch05_Filters} to start.

    {1 Promises (Lwt)}

    The ReWeb stack is completely asychronous and runs using a promise
    runtime. The concrete implementation used currently is
    {{: http://ocsigen.org/lwt/4.1.0/manual/manual} Lwt}, which stands
    for 'light-weight threads'. Lwt provides cooperative multi-tasking
    via promises (a.k.a. 'threads') and a runtime that implements the
    cooperative scheduler and event loop, a lot like NodeJS but with
    some additional powers.

    In programming ReWeb the user should expect to deal with Lwt
    promises fairly frequently. Fortunately the parts of Lwt that should
    be used most often should be familiar:

    [Lwt.return(x)] is like JavaScript's [Promise.resolve(x)]

    {[let getInfo = productId => {
        let%lwt inventory = getInventory(productId);
        let%lwt price = getPrice(productId);

        Lwt.return(mergeInventoryPrice(inventory, price));
      };]}

    ...is like JavaScript's

    {[const getInfo = async (productId) => {
        const inventory = await getInventory(productId);
        const price = await getPrice(productId);

        return mergeInventoryPrice(inventory, price);
      };]}

    Note that you don't have to mark Reason functions as [async]--the
    typechecker infers that automatically from the function return type. *)

