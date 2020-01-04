(** ReWeb - an ergonomic web framework. Start by looking at
    {!module:Server} for an overview of the framework. See [bin/Main.re]
    for an example server.
    
    See {{: https://github.com/yawaramin/re-web/}} for sources. *)

module Body = Body
(** Handle request and response bodies. *)

module Client = Client
(** Make web requests. *)

module Cookies = Cookies

module Form = Form
(** Encode and decode web forms to/from specified types. *)

module Response = Response
(** Send responses. *)

module Server = Server
(** Create and serve endpoints. *)

module Service = Server.Service
(** Services model the request-response pipeline. *)

module Request = Server.Request
(** Read requests. *)

module type Filter = Filter.S
(** Transform services. Please see here for documentation.

    The filters here that don't read the request body additionally
    preserve whatever context was already in the request before the
    current filter ran. They do this by putting the previous context in
    a [prev] method in the new context object. This is just a convention
    but a useful one.

    The filters which read the body don't do this because they only work
    with request which have no context (i.e., context of type [unit]). *)

module Filter = Filter.Make(Request)
(** This is the implementation of the above module type. Please see
    above for documentation. *)

