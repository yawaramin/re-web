module type S = sig
  module Request : Request.S

  type ('ctx, 'resp) t = 'ctx Request.t -> 'resp Lwt.t
  (** A service is an asynchronous function from a request to a
      response. *)

  type ('ctx, 'resp) http = ('ctx, [> Response.http] as 'resp) t
  (** An HTTP service is a service that specifically returns HTTP
      responses (as opposed to WebSocket). *)
end
(** Please see here for API documentation. *)

module Make(R : Request.S) = struct
  module Request = R

  type ('ctx, 'resp) t = 'ctx Request.t -> 'resp Lwt.t
  type ('ctx, 'resp) http = ('ctx, [> Response.http] as 'resp) t
end

