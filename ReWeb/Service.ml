module type S = sig
  module Config : Config.S
  module Request : Request.S

  type ('ctx, 'resp) t = 'ctx Request.t -> 'resp Lwt.t
  (** A service is an asynchronous function from a request to a
      response. *)

  type 'ctx all = ('ctx, [Response.http | Response.websocket]) t
  (** A type modelling services with an intersection of all response
      types. This type is most useful for services which set response
      headers, or come after filters which set response headers. *)
end
(** Please see here for API documentation. *)

module Make(R : Request.S) = struct
  module Request = R
  module Config = Request.Config

  type ('ctx, 'resp) t = 'ctx Request.t -> 'resp Lwt.t
  type 'ctx all = ('ctx, [Response.http | Response.websocket]) t
end

