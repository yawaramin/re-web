(** Filters are middlewares. They plug into the ReWeb request-response
    pipeline and do various tasks, as explained in {!Ch01_Introduction}.

    Filters help to keep services clean, by extracting functionality
    that is not conceptually part of the service. They also help to
    keep code reusable and composeable.

    {1 Creating a filter}

    This section shows how to create filters. To see how to actually
    insert filters into your application, go to {!section:inserting}.

    Here's the simplest possible filter:

    {[let noFilter = service => service;]}

    In other words, that is the 'identity filter'. Remember that a
    service is a function that takes a request and returns a promise of
    a response. So that filter can be written as:

    {[let noFilter = service => request => service(request);]}

    However, due to a ReWeb naming convention and also due to Reason's
    default formatting rules, we normally write filters like this:

    {[let noFilter = (next, request) => next(request);]}

    Here, [next] is a reminder that that is the {i next} service in the
    pipeline after the current filter.

    {2 Doing something in a filter}

    Ultimately, a filter returns a promise of a response. You have two
    main options when you need to return something:

    - Return [next(request)] or [next(some updated request)] on the
      'happy path'
    - Return a response with an HTTP status that indicates an error on
      the sad path

    Here's an example of a filter that validates that there's a
    [SESSION] cookie in the request and returns a 401 Unauthorized
    response otherwise:

    {[let validateSession = (next, request) =>
        switch (request |> Request.cookies |> List.assoc_opt("SESSION")) {
        | Some(_) => next(request)
        | None => `Unauthorized |> Response.of_status |> Lwt.return
        };]}

    This filter gets the request cookies, looks for the [SESSION] cookie
    (the cookies are represented as just a list of pairs of cookie names
    and values), and calls the next request in the pipeline if it was
    found. Otherwise it sends back the unauthorized error response.

    {2 Updating the request context}

    Although interesting, this filter is ultimately not very helpful,
    because although it retrieves the session cookie it actually just
    throws it away again after doing its check. It doesn't pass it
    forward to the [next] service in the pipeline. The next service will
    now need to check for the cookie's presence {i again}, despite the
    filter having already done that.

    Fortunately, there's a better way--we can actually pass the session
    cookie's value to the next request, by using the request
    {i context}. The context is a generically-typed field in the request
    record, and can thus contain any value. The nice thing about this is
    that we can put specifically the session cookie's value which we
    already extracted:

    {[let validateSession = (next, request) =>
        switch (request |> Request.cookies |> List.assoc_opt("SESSION")) {
        | Some(session) => next({...request, ctx: session})
        | None => `Unauthorized |> Response.of_status |> Lwt.return
        };]}

    This filter updates the request's [ctx] field (immutably, i.e.
    creating a new request value) and feeds it to the [next] service.
    The next service in the pipeline can now access the context by
    simply accessing the [request.ctx] field or using the
    {!ReWeb.Request.context} function.

    {3 Preserving existing context}

    However, there is an issue with simply setting the context like we
    have above: there might be some existing value in the context
    already, and updating it loses that. Fortunately, you will get a
    typechecker error if you ever do that inadvertently, because the
    subsequent filters and services would no longer typecheck accessing
    the previous context. But if you would still like to keep the
    previous context, ReWeb has a convention: wrapping it in an object.
    For example:

    {[let validateSession = (next, request) =>
        switch (request |> Request.cookies |> List.assoc_opt("SESSION")) {
        | Some(session) =>
          let ctx = {as _; pub prev = request.ctx; pub session = session};
          next({...request, ctx});
        | None => `Unauthorized |> Response.of_status |> Lwt.return
        };]}

    This creates an
    {{: https://reasonml.github.io/docs/en/object} object} literal which
    has two jobs:

    - Contain the previous context, in a method named [prev]
    - Contain the current session value, in a method named [session]

    Then, it updates the request with this object which becomes the new
    context, and calls the [next] service with the updated request.

    This is one of the few times in Reason when it's very convenient to
    use its object system: when you want to whip up a container to hold
    named values of any types, without having to declare its type first.

    To be honest though, you will get a typechecker error any time you
    change a request pipeline's filters. In my humble opinion this is a
    good thing because it forces you to examine the pipeline from start
    to finish and ensure that it's getting exactly the context it needs
    from its filter chain.

    {3 Accessing wrapped contexts}

    The service which comes after this filter will want to access its
    values. It can do so with:

    - [Request.context(request)#session] to get the session cookie value
    - [Request.context(request)#prev] to get the value of the previous
      context. In fact, if you want to access contexts that were wrapped
      farther back in the filter chain, you would have to do
      [Request.context(request)#prev#prev...].

    {2 Running a filter after a request}

    Filters can not only run before and modify requests, but also run
    after and modify responses. For example, suppose you want to add a
    [X-Response-Time-S] header to every response to inform clients how
    long it took in seconds for your server to create a response. You
    would need to:

    - Capture the current time as the start time
    - Actually call the [next] service with the [request] and get its
      response promise
    - Map over the response promise and inside that, capture the current
      time as the end time, calculate the difference, and add a header
      containing it

    Here's the implementation:

    {[let setResponseTime = (next, request) => {
        let startTime = Unix.gettimeofday();
        let addHeader =
          Response.add_header(
            ~name="x-response-time-s",
            ~value=string_of_float(Unix.gettimeofday() -. startTime),
          );

        request |> next |> Lwt.map(addHeader);
      };]}

    {i Note} that, because of the way the [Response.add_header] function
    is defined, you can partially apply it without the actual [response]
    argument and that will give you the function that you can pass in to
    [Lwt.map]. At a higher level, you can think of [addHeader] as an
    'action' that you do to the response (even though it is really a
    partially-applied function).

    {1:inserting Inserting a filter in the request-response pipeline}

    To set up a filter to run before a service, call the service with
    the filter. For example, suppose you have the following service:

    {[let hello = _ => "Hello, World!" |> Response.of_text |> Lwt.return;]}

    You can {i compose} the filter with a service, e.g.:

    {[noFilter(hello)]}

    Typically I use the
    {{: https://caml.inria.fr/pub/docs/manual-ocaml/libref/Stdlib.html#VAL(@@)} [@@]}
    operator to compose filters:

    {[noFilter @@ hello]}

    This sort of looks like a data flow. As you compose more filters
    together you can sort of visualize them as a left-to-right series of
    filtering actions that happen before the service runs. Here's a more
    complex example:

    {[let hello = request => {
        let _: Ezjsonm.t = Request.context(request)#prev;
        "Hello, World!" |> Response.of_text |> Lwt.return;
      };

      let test = Filter.body_json @@ Filter.basic_auth @@ hello;]}

    What's happening above, starting from the bottom up:

    - We compose two filters and a service
    - The service accesses the context and then its wrapped [prev]
      method to get the request body JSON and typechecks that it
      actually is JSON. And this check happens at compile time!

    As you can see, a filter chain can be composed by following certain
    conditions:

    - The previous filter in the chain needs to 'output' a context type
      that the next filter in the chain can handle
    - Any filter that accesses the request body needs to be {i first} in
      the filter chain
    - The service at the end of the filter chain may access the context
      in a way that type-checks

    These conditions however are enforced at compile time (provided the
    filters are implemented correctly), so you don't need to worry about
    getting them wrong.

    {2 Inserting a filter for a specific scope in the router}

    Because of the design of routers (i.e. servers), you can plug in
    filters at specific route scopes. Suppose you want to parse all
    request bodies as JSON but only at the [/api/...] scope. You can
    write a router specifically for that scope:

    {[let getHeroes = request => {
        let _: Ezjsonm.t = Request.context(request);
        "Heroes!" |> Response.of_text |> Lwt.return;
      };

      let notFound = _ => `Not_found |> Response.of_status |> Lwt.return;

      let apiServer =
        fun
        | (`GET, ["heroes"]) => getHeroes
        | _ => notFound;]}

    The [apiServer] doesn't actually know that it's serving the
    [/api/...] scope. Its services simply access the request context
    JSON and that typechecks, because...

    {[let server =
        fun
        | (meth, ["api", ...path]) =>
          Filter.body_json @@ apiServer @@ (meth, path)
        | _ => notFound;]}

    Its parent [server] pattern-matches on all paths starting with [api]
    and passes them forward (along with the request method) to the
    [apiServer], but only after applying the [body_json] filter so that
    all [apiServer] services will see requests with a context containing
    the body JSON.

    {1 The ReWeb filters}

    ReWeb ships with some built-in filters, which you can see in the
    {!ReWeb.Filter} module. This section shows how to use them.

    {i Note} that, as mentioned in the previous section, the ReWeb
    filters are written in a type-safe and composeable way. For example,
    the type signature of the {!ReWeb.Filter.body_json} filter:

    {[val body_json : (unit, Ezjsonm.t, [> Response.http]) t]}

    If we compare the type parameters to their formal parameter names:

    - ['ctx1] = [unit]
    - ['ctx2] = [Ezjsonm.t]
    - ['resp] = [[> Response.http]]

    This tells us that the filter starts with an 'input' context type of
    [unit] and transforms it into an 'output' context type of
    [Ezjsonm.t] (i.e. a JSON document). And the third type parameter
    says that the response type is HTTP (as opposed to a WebSocket).

    This means that this must be either first in the filter chain or
    must come after filters that don't change the context.

    {2 Basic authentication}

    This filter takes any context and outputs a context containing the
    username and password taken from the request's basic auth
    credentials:

    {[basic_auth @@ service]}

    It responds with an error status response if it can't understand the
    auth header.

    {2 Bearer authentication}

    Takes any context and outputs a context containing bearer token:

    {[bearer_auth @@ service]}

    Error behaviour is like [basic_auth].

    {2 Decode a web form from request body}

    Takes a [unit] context (i.e. a context that has not been touched by
    any other filter) and outputs a context of a custom type that you
    specify. The reason it needs a unit context is that it needs to
    fully read the request body to decode it, and wants to ensure
    nothing else has already read the body.

    For example to decode the following form in a request body into a
    strongly-typed value:

    {[id=1&name=Bob]}

    You can declare the type and its corresponding form decoder:

    {[type user = {id: int, name: string};

      let user = (id, name) => {id, name};
      let userForm = Form.(make(Field.[int("id"), string("name")], user));
      body_form(userForm) @@ service]}

    Note the placements of the parentheses that locally open the
    {!ReWeb.Form} and {!ReWeb.Form.Field} modules. These expose the
    [make] function to create a form and the field list type (which you
    create using the square brackets), and also the field specifier
    functions like [int], [string] which you use to describe the
    fields--specifically their types and names.

    Finally you pass in the [user] constructor to the [make] function
    which actually creates the typed [user] value. The typechecker
    verifies that the user constructor function matches up with the
    types declared for the form.

    {2 Parse request body JSON}

    Takes a unit context and outputs a body JSON context:

    {[body_json @@ service]}

    {2 Decode request body JSON}

    Takes a body JSON context and a JSON decoder and outputs a context
    of a custom type:

    {[let jsonToUser = json => ...;
      body_json_decode(jsonToUser) @@ service]}

    {2 Get request body as a string}

    Takes a unit context and outputs a context of a string containing
    the request body:

    {[body_string @@ service]}

    {2 Set response cache policy}

    Takes any context and returns that context unmodified but with a
    [cache-control] header added to the response. For example to set the
    response to cache anywhere (publicly) for ten minutes:

    {[cache_control(Header.CacheControl.public(~max_age=600)) @@ service]}

    {2 Upload files & decode a multipart form}

    Takes a unit context and returns a context of a custom type in the
    same way as the body form decoder filter, and {i additionally} saves
    any uploaded files sent in the multipart form using the specified
    function to derive the file names:

    {[let path = (~filename, name) => "./form_" ++ name ++ "_" ++ filename;
      multipart_form(userForm, path) @@ service]}

    The [filename] passed in to the [path] function is stripped of any
    directory path beforehand so there's no risk of someone saving a
    file in an unexpected directory.

    {2 Decode form from request URI query}

    Takes any context and returns a context containing a URI query
    decoded into a strong type using the same form decoders as above.
    Also returns the previous context wrapped inside the new context.
    E.g.:

    {[query_form(userForm) @@ service]} *)

