(** ReWeb - an ergonomic web framework. Based on the design proposed in
    {{: https://gist.github.com/yawaramin/f0a24f1b01b193dd6d251e5e43be65e9}} *)

module Body = ReWeb__Body

module Headers = Httpaf.Headers

module Request = ReWeb__Request
(** Read requests. *)

module Response = ReWeb__Response
(** Send responses. *)

module Server = ReWeb__Server
(** Create and serve endpoints. *)
