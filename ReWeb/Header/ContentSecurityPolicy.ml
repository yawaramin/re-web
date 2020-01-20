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

let scheme_to_string = function
  | `HTTP -> "http:"
  | `HTTPS -> "https:"
  | `Data -> "data:"
  | `Mediastream -> "mediastream:"
  | `Blob -> "blob:"
  | `Filesystem -> "filesystem:"

let algo_to_string = function
  | `SHA256 -> "sha256"
  | `SHA384 -> "sha384"
  | `SHA512 -> "sha512"

let src_to_string = function
  | Host host -> host
  | Scheme scheme -> scheme_to_string scheme
  | Self -> "'self'"
  | Unsafe_eval -> "'unsafe-eval'"
  | Unsafe_hashes -> "'unsafe-hashes'"
  | Unsafe_inline -> "'unsafe-inline'"
  | None -> "'none'"
  | Nonce base64 -> "'nonce-" ^ base64 ^ "'"
  | Hash (algo, base64) -> "'" ^ algo_to_string algo ^ "-" ^ base64 ^ "'"

let src_list_to_string ~name src_list =
  let src_list = src_list |> List.map src_to_string |> String.concat " " in
  name ^ " " ^ src_list

let directive_to_string = function
  | Child_src src_list ->
    src_list_to_string ~name:"child-src" src_list
  | Connect_src src_list ->
    src_list_to_string ~name:"connect-src" src_list
  | Default_src src_list ->
    src_list_to_string ~name:"default-src" src_list
  | Font_src src_list ->
    src_list_to_string ~name:"font-src" src_list
  | Frame_src src_list ->
    src_list_to_string ~name:"frame-src" src_list
  | Img_src src_list ->
    src_list_to_string ~name:"img-src" src_list
  | Manifest_src src_list ->
    src_list_to_string ~name:"manifest-src" src_list
  | Media_src src_list ->
    src_list_to_string ~name:"media-src" src_list
  | Object_src src_list ->
    src_list_to_string ~name:"object-src" src_list
  | Prefetch_src src_list ->
    src_list_to_string ~name:"prefetch-src" src_list
  | Script_src src_list ->
    src_list_to_string ~name:"script-src" src_list
  | Script_src_elem src_list ->
    src_list_to_string ~name:"script-src-elem" src_list
  | Script_src_attr src_list ->
    src_list_to_string ~name:"script-src-attr" src_list
  | Style_src src_list ->
    src_list_to_string ~name:"style-src" src_list
  | Style_src_elem src_list ->
    src_list_to_string ~name:"style-src-elem" src_list
  | Style_src_attr src_list ->
    src_list_to_string ~name:"style-src-attr" src_list
  | Worker_src src_list ->
    src_list_to_string ~name:"worker-src" src_list
  | Base_uri src_list ->
    src_list_to_string ~name:"base-uri" src_list
  | Plugin_types plugin_types ->
    "plugin-types " ^ String.concat " " plugin_types
  | Form_action src_list ->
    src_list_to_string ~name:"form-action" src_list
  | Navigate_to src_list ->
    src_list_to_string ~name:"navigate-to" src_list
  | Report_to uris -> "report-uri " ^ String.concat " " uris
  | Block_all_mixed_content -> "block-all-mixed-content"

let to_header ?(report_only=false) directives =
  let name =
    if report_only then "content-security-policy-report-only"
    else "content-security-policy"
  in
  let directives = match directives with
    | [] -> [Default_src [Self]]
    | _ -> directives
  in
  name,
  directives |> List.map directive_to_string |> String.concat "; "

