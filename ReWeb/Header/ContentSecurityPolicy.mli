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

type directive =
| Child_src of src list
| Connect_src of src list
| Default_src of src list
| Font_src of src list
| Frame_src of src list
| Img_src of src list
| Manifest_src of src list
| Media_src of src list
| Object_src of src list
| Prefetch_src of src list
| Script_src of src list
| Script_src_elem of src list
| Script_src_attr of src list
| Style_src of src list
| Style_src_elem of src list
| Style_src_attr of src list
| Worker_src of src list
| Base_uri of src list
| Plugin_types of string list
| Form_action of src list
| Navigate_to of src list
| Report_to of string list
| Block_all_mixed_content

type t = directive list

val to_header : ?report_only:bool -> t -> string * string
(** [to_header(?report_only, directives)] is a either a
    [content-security-policy] header (if [report_only] is [false] which
    is the default), or a [content-security-policy-report-only] header
    if [report_only] is [true].

    If [directives] is an empty list, will output a single
    "default-src 'self'" directive under the assumption that we want
    some protection since we're trying to use CSP. *)

