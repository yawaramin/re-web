(* Convenience functions to get configs from environment variables. *)

let string = Sys.getenv

let bool name = bool_of_string @@ string name

let char name = match string name with
  | "" -> invalid_arg "Reweb.Cfg.char: empty string"
  | string -> String.unsafe_get string 0

let float name = float_of_string @@ string name
let int name = int_of_string @@ string name

(* Reweb actual configs. *)

let filter_csp = try bool "FILTER_CSP" with Not_found -> true
let filter_hsts = try bool "FILTER_HSTS" with Not_found -> true
let secure = try bool "SECURE" with Not_found -> true
let buf_size = try int "BUF_SIZE" with Not_found -> 8192

let num_threads =
  try int "NUM_THREADS" with Not_found -> Domain.recommended_domain_count

let port = try int "PORT" with Not_found -> 8080
