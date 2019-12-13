module H = Httpaf

type t = {envelope : H.Response.t; body : Bigstringaf.t Lwt_stream.t}

let make ~status ~headers ~body {Request.reqd; _} = {
  envelope = H.Response.create ~headers status;
  body;
}

let return service request = request |> service |> Lwt.return

let text ?(status=`OK) ?(content_type="text/plain") body =
  let len = String.length body in
  let headers = H.Headers.of_list [
    "content-type", content_type;
    "connection", "close";
    "content-length", string_of_int len;
  ]
  in
  let body = Lwt_stream.of_list
    [Bigstringaf.of_string ~off:0 ~len body]
  in
  make ~status ~headers ~body

let html ?(status=`OK) = text ~status ~content_type:"text/html"

let json ?(status=`OK) body = body
  |> Ezjsonm.to_string ~minify:true
  |> text ~status ~content_type:"application/json"

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
