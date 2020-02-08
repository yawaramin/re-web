(** A ReWeb request data structure is a thin wrapper over an
    {{: https://docs.mirage.io/httpaf/Httpaf/Reqd/index.html} Httpaf request descriptor}.
    It additionally contains the request query string, and a generic
    'context' value. This makes the request itself generic--in other
    words, the request type exposes the type of context it contains.
    This enables filters and services in the request pipeline to safely
    compose and ensure they only use contexts of the correct type.

    {1 Operations}

    Requests expose simple operations, like {!ReWeb.Request.context},
    {!ReWeb.Request.header}, {!ReWeb.Request.cookies}. These accessors
    are cheap because they don't touch the request body.

    Requests also allow you to read their bodies with
    {!ReWeb.Request.body} and {!ReWeb.Request.body_string}. These
    operations are more expensive and should only be done once per
    request. ReWeb tries to ensure this by requiring that the request's
    body has not already been read, by requiring the input request type
    to be [unit Request.t].

    The reasoning behind this is that top-level requests should be ones
    directly from the client, and not touched by any filters which could
    read the body (because those filters would output requests with a
    different context type, not [unit]). This should hold true as long
    as you ensure that all filters which read request bodies
    appropriately set the context type--i.e. by putting either the body
    directly, or some data derived from the body, in the context.

    The filters that ReWeb ships with, all respect this rule. However,
    it is possible to write filters which don't. So there is a
    possibility of double-reading the body and getting a runtime error.
    Using and building upon the filters in {!ReWeb.Filter} should
    minimize this.

    {1 Request bodies}

    Request bodies are modelled by a variant type {!ReWeb.Body.t}. In
    fact this type is used for both request {i and} response bodies in
    ReWeb and as such contains operations for converting between
    different forms of bodies (streams, single strings) used in
    different parts of ReWeb.

    You will mostly not need to care about dealing with request bodies
    directly if you use one of the provided filters which read and store
    the body.

    One possible exception is if you want to directly echo the request
    body without touching it--in that case you can get the body using
    {!ReWeb.Request.body} and passing it to {!ReWeb.Response.of_http}.
    Remember that request and response bodies are the same type. We will
    cover ReWeb responses in the next chapter. *)

