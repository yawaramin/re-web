(** ReWeb - an ergonomic web framework. Start by looking at
    {!module:Server} for an overview of the framework. See [bin/Main.re]
    for an example server.
    
    See {{: https://github.com/yawaramin/re-web/}} for sources. *)

module Body = Body
(** Handle request and response bodies. *)

module Cache = Cache
(** Concurrent safe caching. *)

module Client = Client
(** Make web requests. *)

module Config = Config
(** Configure and override the behaviour of ReWeb and applications built
    with it. *)

module Form = Form
(** Encode and decode web forms to/from specified types. *)

module Header = Header
(** Create correct response headers. *)

module Response = Response
(** Send responses. *)

module Server = Server
(** Create and serve endpoints. *)

module Service = Server.Service
(** Services model the request-response pipeline. *)

module Request = Server.Request
(** Read requests. *)

module Filter = Server.Filter
(** Transform requests and responses in the pipeline. *)

