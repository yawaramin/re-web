module H = Httpaf

type status = H.Status.t
type t = { envelope : H.Response.t; body : Body.t }

let body { body; _ } = body

let header name { envelope = { H.Response.headers; _ }; _ } =
  H.Headers.get headers name

let headers name { envelope = { H.Response.headers; _ }; _ } =
  H.Headers.get_multi headers name

let make ~status ~headers body = {
  envelope =
    H.Response.create ~headers:(H.Headers.of_list headers) status;
  body;
}

let get_headers ?len content_type =
  let list = ["content-type", content_type; "connection", "close"] in
  match len with
  | Some len -> ("content-length", string_of_int len) :: list
  | None -> list

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

let of_text ?(status=`OK) = of_binary ~status ~content_type:"text/plain"

let of_file ?(status=`OK) ?content_type file_name =
  let f () =
    let content_type =
      Option.value content_type ~default:(get_content_type file_name)
    in
    let open Let.Lwt in
    let* file_descr =
      Lwt_unix.openfile file_name Unix.[O_RDONLY; O_NONBLOCK] 0o400
    in
    let fd = Lwt_unix.unix_file_descr file_descr in
    (* TODO: not sure what [shared] means here, need to find out *)
    let bigstring = Lwt_bytes.map_file ~fd ~shared:false () in
    let+ () = Lwt_unix.close file_descr in
    let body = Body.Single bigstring in
    make ~status ~headers:(get_headers content_type) body
  in
  Lwt.catch f @@ function
    | Unix.Unix_error (Unix.ENOENT, _, _) ->
      let msg = "ReWeb.Response.of_file: file not found: " ^ file_name in
      msg |> of_text ~status:`Not_found |> Lwt.return
    | exn -> raise exn

let status { envelope = { H.Response.status; _ }; _ } = status

