(** Use {!make} (see below) to create a www form that can be decoded to
    custom types using the form validation rules defined in fields. Use
    {!encode} to encode a value as a form. *)

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
  (** [bool(name)] returns a boolean field named [name]. *)

  val ensure : ('a -> bool) -> 'a t -> 'a t
  (** [ensure(pred, field)] returns a field that will succeed decoding a
      value [a] of type ['a] if [pred(a)] is [true]. Otherwise it will
      fail decoding. *)

  val float : string -> float t
  (** [float(name)] returns a float field named [name]. *)

  val int : string -> int t
  (** [int(name)] returns an integer field named [name]. *)

  val make : string -> 'a decoder -> 'a t
  (** [make(name, decoder)] returns a field with a [decoder] of type
      ['a]. *)

  val string : string -> string t
  (** [string(name)] returns a string field named [name]. *)
end
(** Allows creating a list of form fields using normal list syntax with
    a local open (e.g. [Field.[bool("remember-me"), string("username")]] *)

type ('ctor, 'ty) t
(** A web form is a list of fields and a 'constructor' that takes their
    decoded field values and returns a value of type ['ty]. *)

val decoder : ('ctor, 'ty) t -> 'ty decoder
(** [decoder(form)] takes a form definition (see above) and returns a
    decoder from that form to a type ['ty]. *)

val encode : ('ty -> (string * string) list) -> 'ty -> string
(** [encode(fields, value)] is a query-encoded string form. It calls
    [fields value] to get the representation of [value] as a list of
    key-value string pairs. *)

val make : ('ctor, 'ty) Field.list -> 'ctor -> ('ctor, 'ty) t
(** [make(fields, ctor)] allows creating a form that can be used to
    decode (with {!decoder}) www forms. *)

