(** Filters are middlewares. They plug into the ReWeb request-response
    pipeline and do various tasks, as explained in {!Ch01_Introduction}.

    Filters help to keep services clean, by extracting functionality
    that is not conceptually part of the service. They also help to
    keep code reusable and composeable. Here's the simplest possible
    filter:

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

    {1 Doing something in a filter}

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

    {1 Updating the request context}

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

    {2 Preserving existing context}

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

    To be honest though, you will get a typechecker error any type you
    change a request pipeline's filters. In my humble opinion this is a
    good thing because it forces you to examine the pipeline from start
    to finish and ensure that it's getting exactly the context it needs
    from its filter chain.

    {2 Accessing wrapped contexts}

    The service which comes after this filter will want to access its
    values. It can do so with:

    - [Request.context(request)#session] to get the session cookie value
    - [Request.context(request)#prev] to get the value of the previous
      context. In fact, if you want to access contexts that were wrapped
      farther back in the filter chain, you would have to do
      [Request.context(request)#prev#prev...].

    {1 Running a filter after a request}

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

    {1 The ReWeb filters}

    ReWeb ships with some built-in filters, which you can see in the
    {!ReWeb.Filter} module. Currently, there are filters to validate
    Basic Auth and Bearer Token credentials, parse and decode a JSON
    body, decode a web form, upload files with multipart form encoding
    while also optionally decoding a web form, and decode a query string
    as a form. See the API docs for details.

    I expect to add more filters either to [ReWeb.Filter] module itself
    or as addon packages as appropriate. (Anyone can create ReWeb
    filters and publish them as packages.) *)

