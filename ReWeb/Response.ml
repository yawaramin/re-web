module H = Httpaf

type status = H.Status.t
type t = {envelope : H.Response.t; body : Body.t}

let make ~status ~headers body = {
  envelope = H.Response.create ~headers status;
  body;
}

let get_headers ?len content_type =
  let list = ["content-type", content_type; "connection", "close"] in
  H.Headers.of_list (match len with
    | Some len -> ("content-length", string_of_int len) :: list
    | None -> list)

let binary ?(status=`OK) ?(content_type="application/octet-stream") body =
  let len = String.length body in
  make
    ~status
    ~headers:(get_headers ~len content_type)
    (Single (Bigstringaf.of_string ~off:0 ~len body))

let html ?(status=`OK) = binary ~status ~content_type:"text/html"

let json ?(status=`OK) body = body
  |> Ezjsonm.to_string ~minify:true
  |> binary ~status ~content_type:"application/json"

let get_content_type file_name = match Filename.extension file_name with
  | "html" | "htm" -> "text/html"
  | "text" | "txt" -> "text/plain"
  | "json" -> "application/json"
  | _ -> "application/octet-stream"

let make_chunk line =
  let off = 0 in
  let len = String.length line + 1 in
  {
    Body.off;
    len;
    bigstring = Bigstringaf.of_string ~off ~len (line ^ "\n");
  }

let static ?(status=`OK) ?content_type file_name =
  let open Lwt_let in
  let content_type =
    Option.value content_type ~default:(get_content_type file_name)
  in
  let+ channel = Lwt_io.(open_file ~perm:0o400 ~mode:Input file_name) in
  let lines = Lwt_io.read_lines channel in
  let body = Body.Multi (Lwt_stream.map make_chunk lines) in
  make ~status ~headers:(get_headers content_type) body

let text ?(status=`OK) = binary ~status ~content_type:"text/plain"

(*
type headers = (string * string) list

type t = {
  assigns: Ezjsonm.t;
  body: Bigstringaf.t Lwt_stream.t;
  cookies: headers;
  headers: headers;
  status: Httpaf.Status.t;
}

let (or) option default = match option with
  | Some value -> value
  | None -> default

(* NOTE: it's important to use [set] to implement the rest of the
   response update functions, because it maintains the invariants of the
   response. *)

let set ?status ?body ?(assigns=Ezjsonm.dict []) ?(headers=[]) ?(cookies=[]) response =
  let open Ezjsonm in
  let new_dict = assigns |> value |> get_dict in
  let assigns = dict (new_dict @ get_dict (value response.assigns)) in
  let body = body or response.body in
  let cookies = cookies @ response.cookies in
  let headers = headers @ response.headers in
  let status = status or response.status in
  {assigns; body; cookies; headers; status}

let content_type_header filetype = [
  "content-type", match filetype with
    | "htm" | "html" -> "text/html"
    | "json" -> "application/json"
    | "txt" | "text" -> "text/plain"
    | _ -> "application/octet-stream"
]

let empty = {
  assigns = Ezjsonm.dict [];
  body = Lwt_stream.of_list [];
  cookies = [];
  headers = [];
  status = `OK;
}

(* TODO: find a templating engine that can render the result in chunks to
   the stream. Also, ingest templates at compilation, not runtime. *)
let render ?(status=`OK) ?(assigns=Ezjsonm.dict []) ~template response =
  let headers = match String.rindex template '.' with
    | exception Not_found -> []
    | dot_index ->
      let offset = dot_index + 1 in
      let length = String.length template - offset in
      let content_type_header =
        length |> String.sub template offset |> content_type_header
      in
      content_type_header
  in
  let template = "template/" ^ template in
  let body = 0o644
    |> Unix.(openfile template [O_RDONLY])
    |> Lwt_io.of_unix_fd ~mode:Lwt_io.input
  in
  set ~status ~headers ~body ~assigns response

let not_found ?(template="not-found.mustache.html") response =
  render ~status:`Not_found ~template response

let to_byte_channel string = string
  |> Lwt_bytes.of_string
  |> Lwt_io.(of_bytes ~mode:input)

let html string response =
  let headers = content_type_header "html" in
  let body = to_byte_channel string in
  set ~headers ~body response

let json value response =
  let headers = content_type_header "json" in
  let body = value |> Ezjsonm.to_string |> to_byte_channel in
  set ~headers ~body response

let text string response =
  let headers = content_type_header "txt" in
  let body = to_byte_channel string in
  set ~headers ~body response
*)
