module H = Httpaf

type status = H.Status.t
type t = { envelope : H.Response.t; body : Body.t }

let body { body; _ } = body

let header name { envelope = { H.Response.headers; _ }; _ } =
  H.Headers.get headers name

let headers name { envelope = { H.Response.headers; _ }; _ } =
  H.Headers.get_multi headers name

let make ~status ~headers body = {
  envelope = H.Response.create ~headers status;
  body;
}

let get_headers ?len content_type =
  let list = ["content-type", content_type; "connection", "close"] in
  H.Headers.of_list (match len with
    | Some len -> ("content-length", string_of_int len) :: list
    | None -> list)

let of_binary ?(status=`OK) ?(content_type="application/octet-stream") body =
  let len = String.length body in
  make
    ~status
    ~headers:(get_headers ~len content_type)
    (Single (Bigstringaf.of_string ~off:0 ~len body))

let of_html ?(status=`OK) = of_binary ~status ~content_type:"text/html"

let of_json ?(status=`OK) body = body
  |> Ezjsonm.to_string ~minify:true
  |> of_binary ~status ~content_type:"application/json"

let get_content_type file_name = match Filename.extension file_name with
  | ".bmp" -> "image/bmp"
  | ".css" -> "text/css"
  | ".csv" -> "text/csv"
  | ".gif" -> "image/gif"
  | ".html" | ".htm" -> "text/html"
  | ".ico" -> "image/x-icon"
  | ".jpeg" | ".jpg" -> "image/jpeg"
  | ".js" -> "text/javascript"
  | ".json" -> "application/json"
  | ".mp4" -> "video/mp4"
  | ".png" -> "image/png"
  | ".svg" -> "image/svg+xml"
  | ".text" | ".txt" -> "text/plain"
  | ".tiff" -> "image/tiff"
  | ".webp" -> "image/webp"
  | _ -> "application/octet-stream"

let make_chunk ?(lines=true) line =
  let off = 0 in
  let len = String.length line in
  let len, line = if lines then len + 1, line ^ "\n" else len, line in
  { H.IOVec.off; len; buffer = Bigstringaf.of_string ~off ~len line }

let of_view ?(status=`OK) ?(content_type="text/html") view =
  let stream, push_to_stream = Lwt_stream.create () in
  let p string = push_to_stream (Some (make_chunk ~lines:false string)) in
  view p;
  push_to_stream None;
  make ~status ~headers:(get_headers content_type) (Body.Multi stream)

let of_file ?(status=`OK) ?content_type file_name =
  let open Lwt_let in
  let content_type =
    Option.value content_type ~default:(get_content_type file_name)
  in
  let+ channel = Lwt_io.(open_file ~perm:0o400 ~mode:Input file_name) in
  let lines = Lwt_io.read_lines channel in
  let body = Body.Multi (Lwt_stream.map make_chunk lines) in
  make ~status ~headers:(get_headers content_type) body

let of_text ?(status=`OK) = of_binary ~status ~content_type:"text/plain"

let status { envelope = { H.Response.status; _ }; _ } = status

