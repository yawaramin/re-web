type 'a decoder = string -> ('a, string) result
(** A decoder is a function that takes an encoded value and returns a
    result of decoding the value. *)

module Field : sig
  type 'a t
  (** A form field is a field name and a decoder function for the field. *)

  type (_, _) list =
  | [] : ('a, 'a) list
  | (::) : 'a t * ('b, 'c) list -> ('a -> 'b, 'c) list (**)
  (** Used to create a form field list. *)

  val bool : string -> bool t
  val float : string -> float t
  val int : string -> int t
  val make : string -> 'a decoder -> 'a t
  val string : string -> string t
end

type ('ctor, 'ty) t
(** A web form is a list of fields and a 'constructor' that takes their
    decoded field values and returns a value of type ['ty]. *)

val decoder : ('ctor, 'ty) t -> 'ty decoder
(** [decoder form] takes a form definition (see above) and returns a
    decoder from that form to a type ['ty]. *)

val make : ('ctor, 'ty) Field.list -> 'ctor -> ('ctor, 'ty) t
