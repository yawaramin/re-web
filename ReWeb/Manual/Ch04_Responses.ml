(** Sending responses forms perhaps the largest portion of the ReWeb API
    surface area. While requests are relatively simple, responses can be
    created and accessed in a variety of ways. The key point to remember
    is that ReWeb responses are the {i same data type} as
    {!ReWeb.Client} responses. In other words, if you make a web client
    request in ReWeb as part of handling your client's request, you can
    potentially unwrap and send back exactly that response to {i your}
    client.

    That said, there is a slight nuance. In ReWeb you can write a
    response that is a standard HTTP response, or one that is actually a
    WebSocket server. The latter will cause a WebSocket connection to be
    established and handled as specified. These are modelled at the type
    level:

    {[type t('resp) = [> http | websocket] as 'resp;]}

    This is saying that when you have a [Response.t('resp)], it could be
    an HTTP {i or} a WebSocket response. This level of type detail
    ensures that the correct operations will work on HTTP or WebSocket
    responses.

    {1 HTTP responses}

    HTTP responses are defined as an 'envelope' and a body. The envelope
    specifies the response headers and status. The body is the same body
    type we came across in {!ReWeb.Manual.Ch03_Requests}--all HTTP
    bodies in ReWeb are handled with the same data type.

    {2 Creation}

    You can create HTTP responses in a variety of ways:

    - By content type: text, JSON, HTML, binary
    - From a file in the filesystem
    - From a 'view' that is a rendering function
    - By status code
    - With a 301 redirect

    All response creator functions start with the prefix [of_] and all
    accept the response status and headers to set as optional parameters
    with reasonable defaults. There are lots of examples in the [bin/]
    directory but the following sections have some pertinent details:

    {3 Content type}

    These convenience functions, like [of_binary], [of_html], [of_json],
    etc., set the [content-type] response header correctly. As
    mentioned, they also take the response status, headers, and cookies
    as optional parameters. They will allow you to pass in the
    [content-type] header as well--it's up to you to manage that.

    {3 Static file}

    The {!ReWeb.Response.of_file} function is meant to be used for
    sending out static files from the server's filesystem as fast as
    possible. Refer to the API doc for details.

    {3 View}

    The {!ReWeb.Response.of_view} function allows rendering a view. What
    ReWeb calls a view, may look slightly different than you are used
    to. A ReWeb view is a function that takes a 'printer' function (I
    typically call it [p]) and calls it one or more times with strings
    to render.

    Here's what a simple view might look like:

    {[let helloWorld = p => {
        p("Hello, ");
        p("World!");
      };

      helloWorld |> Response.of_view |> Lwt.return;]}

    The printer function pushes its input string out into the response
    body stream. This ensures that rendering happens as fast as
    possible.

    Of course the above view is not very useful, because you could
    easily have sent a static text response. Views get more useful when
    you give them some parameters:

    {[let helloName = (~name, p) => {
        p("Hello, ");
        p(name);
        p("!");
      };

      helloName(~name="Bob") |> Response.of_view |> Lwt.return;]}

    This view interpolates the [name] parameter into the response body.
    It works because of Reason's automatic function currying. When you
    call [helloName(~name="Bob")], you get back a partially-applied
    function with the exact type that [of_view] needs. This will work
    with any number of parameters as long as the [p] parameter is the
    last one in the function.

    Note that views can be any content. ReWeb doesn't care about what's
    inside them--text, HTML, JSON, whatever. It just pushes out strings
    to the response body stream.

    I am planning to include a 'view compiler' in ReWeb to make writing
    views easier. In the future views should look like template files
    that you might come across in other frameworks. When your ReWeb
    project is built, these template files will be compiled into the
    view functions you see above. This will make the template files
    type-safe as well.

    {3 Status code}

    {!ReWeb.Response.of_status} is a convenience function to help you
    quickly return a standard boilerplate status message. See the API
    doc for details.

    {3 Redirect}

    {!ReWeb.Response.of_redirect} is a convenience function to respond
    with a 301 Redirect status to a given location.

    {2 Accessing}

    The response accessor functions allow you to get and set headers,
    get cookies, and get the response body. Moreover, they only work on
    the specific types of responses for which they are appropriate. For
    example, you can get a header from {i any} response (HTTP or
    WebSocket):

    {[let contentType = Response.header("content-type", anyResponse);]}

    However, you can only get the {i body} from an HTTP response:

    {[let body = Response.body(httpResponse);]}

    As mentioned above this is enforced at the type level, and you will
    get a type error if these rules are not followed.

    {1 WebSocket responses}

    The {!ReWeb.Response.of_websocket} function returns specifically a
    WebSocket (WS) response. It requires you to pass in a [handler]
    function (and optional response headers). The handler function
    returns a promise that should run for the lifetime of the WS. The
    lifetime of the handler's promise, determines the lifetime of the WS
    from the server side. Here's a simple example of a WS that sends a
    single message to the client and then exits immediately:

    {[let ws = Response.of_websocket((_pull, push) =>
        "Hello, World!" |> push |> Lwt.return
      );]}

    ReWeb calls the handler function with two functions: [pull] and
    [push]. These functions let you send and receive messages to/from
    the client while inside the WS handler's function body. Pushing a
    message is synchronous and instant. (That's why you can send its
    result into [Lwt.return] to resolve the handler promise
    immediately.)

    {i Pulling} a message from the WS is asynchronous because the client
    may not have sent a message yet. In fact, they may not send a
    message for a long time, if ever. Hence the [pull] function actually
    needs you to tell it how long to wait for a
    message--[pull(floatSeconds)], and returns a
    promise--[Lwt.t(option(string))], representing the fact that it's
    asynchronous and that it might have timed out and hence it didn't
    get a message.

    Here's an example of pulling:

    {[let ws = Response.of_websocket((pull, _push) =>
        1.
        |> pull
        |> Lwt.map(fun
            | Some(string) => print_endline(string)
            | None => print_endline("(None)")
          );]}

    This handler pulls a message from the connection, waiting for one
    second maximum. Then, because it gets back a promise, it maps over
    the promise to return the required type, [Lwt.t(unit)], by just
    printing out whatever string it got (or none). By doing so it exits
    and closes the WS.

    {2 Continuously-running handlers}

    You probably noticed that in both of the above examples, the handler
    exited after doing just one thing, but in a normal WS connection you
    actually want the handler to keep running. You can do this with a
    ReWeb handler by using
    {{: https://reasonml.github.io/docs/en/function.html#recursive-functions} recursion}.
    For example:

    {[let rec handler = (pull, push) => {
        let%lwt message = pull(2.);

        switch (Option.map(String.trim, message)) {
        | Some("close") => Lwt.return_unit
        | Some(message) =>
          push(message);
          handler(pull, push);
        };
      };

      let ws = Response.of_websocket(handler);]}

    In this example, [handler] is recursive (defined with [let rec]) and
    calls itself to keep the promise running continuously. The promise
    polls for a new message every two seconds, checks if the message is
    'close' and if so closes the connection. Otherwise it echoes the
    message and keeps going.

    {2 Handlers with internal state}

    Since a handler just has to return a function that looks like
    [(pull, push) => Lwt.t(unit)] (roughly), you can actually create
    handlers that have {i more} parameters and then call them with some
    initial values. This is the same 'trick' (partial application) we're
    using to pass parameters to views. Here's an example:

    {[let rec handler = (~doTimes, pull, push) =>
        if (doTimes == 0) {
          Lwt.return_unit;
        } else {
          let%lwt message = pull(2.);
          push(message);
          handler(~doTimes=pred(doTimes), pull, push);
        };

      let ws = Response.of_websocket(handler(~doTimes=5));]}

    In this example we just echo incoming messages but only 5 times,
    after which we close the connection. Notice how the handler
    maintains its own internal state by using the recursive call to pass
    in a different value of [doTimes]. [pred] is a built-in standard
    library function; it returns the 'predecessor' (i.e. one less) of
    the integer passed to it. *)

