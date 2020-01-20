(** Convenience module for creating a
    {{: https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Content-Security-Policy} Content-Security-Policy}
    header. {i Note} that to set up a reporting endpoint properly, you
    will need to use {!ReWeb.Filter.csp}. *)

type src =
| Host of string
| Scheme of [`HTTP | `HTTPS | `Data | `Mediastream | `Blob | `Filesystem]
| Self
| Unsafe_eval
| Unsafe_hashes
| Unsafe_inline
| None
| Nonce of string
| Hash of [`SHA256 | `SHA384 | `SHA512] * string

type src_list = src list option

type t = private {
  child_src : src_list;
  connect_src : src_list;
  default_src : src list;
  font_src : src_list;
  frame_src : src_list;
  img_src : src_list;
  manifest_src : src_list;
  media_src : src_list;
  object_src : src_list;
  prefetch_src : src_list;
  script_src : src_list;
  script_src_elem : src_list;
  script_src_attr : src_list;
  style_src : src_list;
  style_src_elem : src_list;
  style_src_attr : src_list;
  worker_src : src_list;
  base_uri : src_list;
  plugin_types : string list option;
  form_action : src_list;
  navigate_to : src_list;
  report_to : string list option;
  block_all_mixed_content : bool option;
}
(** CSP header value data model. *)

val has_report_to : string list option -> bool

val make :
  ?child_src:src list ->
  ?connect_src:src list ->
  ?font_src:src list ->
  ?frame_src:src list ->
  ?img_src:src list ->
  ?manifest_src:src list ->
  ?media_src:src list ->
  ?object_src:src list ->
  ?prefetch_src:src list ->
  ?script_src:src list ->
  ?script_src_elem:src list ->
  ?script_src_attr:src list ->
  ?style_src:src list ->
  ?style_src_elem:src list ->
  ?style_src_attr:src list ->
  ?worker_src:src list ->
  ?base_uri:src list ->
  ?plugin_types:string list ->
  ?form_action:src list ->
  ?navigate_to:src list ->
  ?report_to:string list ->
  ?block_all_mixed_content:bool ->
  src list ->
  t
(** [make(..., default_src)] is a content security policy consisting of
    the given options. *)

val report_to_header : t -> string * string
(** [report_to_string(directives)] is a valid [Report-To] header using
    the [directives]. *)

val to_header : ?report_only:bool -> t -> string * string
(** [to_header(?report_only, directives)] is a either a
    [content-security-policy] header (if [report_only] is [false] which
    is the default), or a [content-security-policy-report-only] header
    if [report_only] is [true].

    If [directives] just contains empty lists, [to_header] will output
    the [default-src 'self'] directive under the assumption that you
    want some protection since you're trying to use CSP. *)

