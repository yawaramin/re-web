(** You can use and override this configuration by setting the values of
    environment variables with names derived from the names in the [S]
    module type below by prefixing [REWEB__]. For example,
    [REWEB__buf_size].

    Or, you can build a new config module that
    conforms to the [S] signature either by [include]ing the [Default]
    module and shadowing its values as appropriate, or by creating a new
    module from scratch. Then you would pass in this config module to
    those functors in ReWeb which accept a config, like {!ReWeb__Request.Make}. *)

let string name = Sys.getenv_opt @@ "REWEB__" ^ name
(** [string(name)] gets a value from the system environment variable
    with the name [REWEB__name]. The following functions all use the
    same name prefix and work for their specific types. *)

let bool name = Option.bind (string name) bool_of_string_opt

let char_of_string_opt = function
  | "" -> None
  | string -> Some (String.unsafe_get string 0)

let char name = Option.bind (string name) char_of_string_opt
(** [char(name)] gets the first character of the value of the system
    environment variable named [REWEB__name]. *)

let float name = Option.bind (string name) float_of_string_opt
let int name = Option.bind (string name) int_of_string_opt

module type S = sig
  val buf_size : int
  (** Buffer size for internal string/bigstring handling. *)
end
(** The known ReWeb configuration settings. *)

module Default : S = struct
  let buf_size = "buf_size"
    |> int
    |> Option.value ~default:(Lwt_io.default_buffer_size ())
end
(** Default values for ReWeb configuration settings. *)

