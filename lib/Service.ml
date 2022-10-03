module type S = sig
  module Request : Request.S

  type 'ctx t = 'ctx Request.t -> Response.t
  (** A service is a function from a request to a response. *)
end
(** Please see here for API documentation. *)

module Make(R : Request.S) = struct
  module Request = R
  type 'ctx t = 'ctx Request.t -> Response.t
end
