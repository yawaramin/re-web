type 'a decoder = string -> ('a, string) result
(** A decoder is a function that takes an encoded value and returns a
    result of decoding the value. *)

type 'a field
(** A form field is a field name and a decoder function for the field. *)

module Fields : sig
  type (_, _) t =
  | [] : ('a, 'a) t
  | (::) : 'a field * ('b, 'c) t -> ('a -> 'b, 'c) t (**)
  (** Used to create a form field list. *)
end

type ('ctor, 'ty) t
(** A web form is a list of fields and a 'constructor' that takes their
    decoded field values and returns a value of type ['ty]. *)

val decoder : ('ctor, 'ty) t -> 'ty decoder
(** [decoder form] takes a form definition (see above) and returns a
    decoder from that form to a type ['ty]. *)

val field : string -> 'a decoder -> 'a field
val make : ('ctor, 'ty) Fields.t -> 'ctor -> ('ctor, 'ty) t
