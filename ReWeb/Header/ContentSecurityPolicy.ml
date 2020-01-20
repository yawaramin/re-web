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

type t = {
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

let make
  ?child_src
  ?connect_src
  ?font_src
  ?frame_src
  ?img_src
  ?manifest_src
  ?media_src
  ?object_src
  ?prefetch_src
  ?script_src
  ?script_src_elem
  ?script_src_attr
  ?style_src
  ?style_src_elem
  ?style_src_attr
  ?worker_src
  ?base_uri
  ?plugin_types
  ?form_action
  ?navigate_to
  ?report_to
  ?block_all_mixed_content
  default_src = {
  child_src;
  connect_src;
  default_src =
    begin match default_src with
      | [] -> [Self]
      | _ -> default_src
    end;
  font_src;
  frame_src;
  img_src;
  manifest_src;
  media_src;
  object_src;
  prefetch_src;
  script_src;
  script_src_elem;
  script_src_attr;
  style_src;
  style_src_elem;
  style_src_attr;
  worker_src;
  base_uri;
  plugin_types;
  form_action;
  navigate_to;
  report_to;
  block_all_mixed_content;
}

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

let src_list_to_string ~name = function
  | Option.None
  | Some [] -> ""
  | Some src_list ->
    let src_list = src_list |> List.map src_to_string |> String.concat " " in
    name ^ " " ^ src_list

let string_list_to_string ~name = function
  | Option.None
  | Some [] -> ""
  | Some list -> name ^ " " ^ String.concat " " list

let to_header ?(report_only=false) {
  child_src;
  connect_src;
  default_src;
  font_src;
  frame_src;
  img_src;
  manifest_src;
  media_src;
  object_src;
  prefetch_src;
  script_src;
  script_src_elem;
  script_src_attr;
  style_src;
  style_src_elem;
  style_src_attr;
  worker_src;
  base_uri;
  plugin_types;
  form_action;
  navigate_to;
  report_to;
  block_all_mixed_content;
} =
  let name =
    if report_only then "content-security-policy-report-only"
    else "content-security-policy"
  in
  let directives = [
    src_list_to_string ~name:"child-src" child_src;
    src_list_to_string ~name:"connect-src" connect_src;
    src_list_to_string ~name:"default-src" (Some default_src);
    src_list_to_string ~name:"font-src" font_src;
    src_list_to_string ~name:"frame-src" frame_src;
    src_list_to_string ~name:"img-src" img_src;
    src_list_to_string ~name:"manifest-src" manifest_src;
    src_list_to_string ~name:"media-src" media_src;
    src_list_to_string ~name:"object-src" object_src;
    src_list_to_string ~name:"prefetch-src" prefetch_src;
    src_list_to_string ~name:"script-src" script_src;
    src_list_to_string ~name:"script_src-elem" script_src_elem;
    src_list_to_string ~name:"script_src-attr" script_src_attr;
    src_list_to_string ~name:"style-src" style_src;
    src_list_to_string ~name:"style_src-elem" style_src_elem;
    src_list_to_string ~name:"style_src-attr" style_src_attr;
    src_list_to_string ~name:"worker-src" worker_src;
    src_list_to_string ~name:"base-uri" base_uri;
    string_list_to_string ~name:"plugin-types" plugin_types;
    src_list_to_string ~name:"form-action" form_action;
    src_list_to_string ~name:"navigate-to" navigate_to;
    string_list_to_string ~name:"report-uri" report_to;
    match block_all_mixed_content with
    | Some true -> "block-all-mixed-content"
    | _ -> "";
  ]
  in
  name,
  directives |> List.filter ((<>) "") |> String.concat "; "

