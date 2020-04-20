(** A ReWeb server is a function that takes a route as input and
    returns a service as output. A route is a pair of HTTP method and
    path segment list, and a service is a function from a request to a
    promise of response.

    {1 Defining a server}

    One of the simplest possible servers:

    {[let server = _route => _request =>
        Lwt.return(ReWeb.Response.of_text("Hello, World!"));]}

    Because of Reason's auto-curried function syntax, this will normally
    be written:

    {[let server = (_route, _request) =>
        "Hello, World!" |> ReWeb.Response.of_text |> Lwt.return;]}

    A server is not run immediately when it is created (because it is a
    function). Recall from above that the final output of the server is
    a {i promise} of a response. In other words, servers are completely
    asynchronous from the top down. However when the server is supplied
    both a route and a request, it will run. This is done by the
    [Server.serve] function:

    {1 Running a server}

    {[ReWeb.Server.serve(server);]}

    This is ReWeb's entry point into the application. The [server] would
    now be called with every incoming route and request.

    {1 Matching routes}

    A ReWeb server is also automatically a router. This is because its
    first parameter is a [route], which is defined as a pair (tuple) of
    HTTP method, and path segment list. Both of these are
    pattern-matchable:

    - An HTTP method is a polymorphic variant type defined with the
      valid HTTP verbs, e.g. [`GET], [`POST], [`DELETE], and so on. You
      can see the
      {{: https://b0-system.github.io/odig/doc@odoc.default/httpaf/Httpaf/Method/index.html} Httpaf.Method}
      module documentation for details.
    - A path segment list is a list of strings created by splitting up
      the request path into its segments: e.g. [/api/users/1] becomes
      [["api", "users", "1"]]. Note that all path segments become
      strings, even the [1]. If you need it as an [int] you will need to
      convert it (with e.g. [int_of_string(id)]).

    Here's an example of a route being matched:

    {[let server = fun
        | (`GET, ["api", "users", id]) => getUser(id)
        | _ => notFound;]}

    The path is converted into the segment list by:

    - Stripping away the query string if any
    - Converting to a string list with [String.split_on_char('/', path)]
    - Stripping off the list head which would be an empty string because
      paths always start with [/].

    So e.g. the index path [/] would be: [[""]]. And [/docs/] would be:
    [["docs", ""]].

    When pattern-matching, all the normal rules of pattern matching in
    OCaml/ReasonML apply: matching literals, capturing parts or all of
    the matched pattern in bindings, as-patterns, or-patterns, and so
    on. Hence route matching is quite flexible.

    Pattern-matched routes also offer two other big advantages:

    - The compiler warns you if you forget to {i exhaustively} handle
      routes, i.e. if you don't include a catch-all path at the bottom
      of the router
    - The compiler warns you if you handle the same route twice

    These features are quite difficult to get with other systems. We get
    them for 'free' with OCaml/Reason's compiler and the simple routing
    system used in ReWeb.

    {1 Scoping routes}

    Because servers are just functions, you can define more than one and
    call 'child' servers from 'parent' servers. The response returned
    from the child server is then returned from the parent. One very
    useful consequence of this is that you can scope child servers to
    specific route scopes. E.g.:

    {[let apiServer = fun
        | (`GET, ["users", id]) => Services.Api.getUser(id)
        | _ => notFound;

      let server = fun
        | (meth, ["api", ...path]) => apiServer @@ (meth, path)
        | _ => notFound;]}

    {i Note} [@@] is a convenience operator for applying an argument (in
    this case the pair [(meth, path)]) to a function (in this case
    [apiServer]). We will use it to 'chain' together filters, servers,
    and services.

    Here the main [server] is delegating all requests to [/api/...]
    endpoints to the [apiServer], by passing it the request method and
    the {i tail} of the path segment list, which is everything after
    [/api]. Again this is simple because of pattern-matching: we can
    split up the path segment list into a head and a tail, check that
    the head is [api], and pass the tail forward.

    This technique is especially useful with filters, which we will
    cover in a future chapter.

    {1 Setting up a resource}

    You can set up a {i resource,} which is a normal server created with
    the {!ReWeb.Server.resource} function. A resource in ReWeb is the
    same as the one in
    {{: https://guides.rubyonrails.org/getting_started.html#getting-up-and-running} Rails},
    in other words--a set of routes that manage the CRUD operations of a
    collection of objects.

    Resources involve several concepts--requests, responses, and usually
    also views and web forms with some JavaScript that can send the
    proper requests that web forms in browsers unfortunately can't. You
    will learn about all these concepts in the upcoming chapters, but
    for now here's a rough sketch of what a resource might look like:

    {[// Article.re

      // Renders various pages that deal with the resource
      module View = {
        let index = p => ...;
        let new_ = p => ...;
        let edit = (~id, p) => ...;
        let show = (~id, p) => ...;
      };

      // These are the services that handle the routes
      let index = _ => View.index |> Response.of_view |> Lwt.return;
      let create = _ => ...;
      let new_ = _ => View.new_ |> Response.of_view |> Lwt.return;
      let edit = (id, _) => View.edit(~id) |> Response.of_view |> Lwt.return;
      let show = (id, _) => View.show(~id) |> Response.of_view |> Lwt.return;
      let update = (meth, id, _) => ...;
      let destroy = (id, _) => ...;

      // This is the server that routes the requests to the correct services:
      let resource = route => Server.resource(
        ~index,
        ~create,
        ~new_,
        ~edit,
        ~show,
        ~update,
        ~destroy,
        route,
      );]}

    Recall from the previous section that you can set up a child server
    to handle the routes in a certain scope. So with this resource you
    can set it up to handle the [/articles/...] scope:

    {[let server = fun
        | (meth, ["articles", ...path]) => Article.resource @@ (meth, path)
        | _ => notFound;]}

    The nice thing about the [Server.resource] function is that it sets
    up all the [GET] routes to be valid both with a trailing slash and
    without. *)

