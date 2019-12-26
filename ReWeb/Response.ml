module H = Httpaf

type cookies = (string * string) list
type headers = (string * string) list
type status = H.Status.t
type t = { envelope : H.Response.t; body : Body.t }

let body { body; _ } = body

let cookies { envelope = { H.Response.headers; _ }; _ } = "set-cookie"
  |> H.Headers.get_multi headers
  |> Cookies.of_headers

let header name { envelope = { H.Response.headers; _ }; _ } =
  H.Headers.get headers name

let headers name { envelope = { H.Response.headers; _ }; _ } =
  H.Headers.get_multi headers name

let make ~status ~headers body = {
  envelope =
    H.Response.create ~headers:(H.Headers.of_list headers) status;
  body;
}

let cookie_to_header (name, value) = "set-cookie", name ^ "=" ^ value

let make_headers ?(headers=[]) ?(cookies=[]) ?content_length content_type =
  let cookie_headers = List.map cookie_to_header cookies in
  let headers = headers
    @ ["content-type", content_type; "connection", "close"]
    @ cookie_headers
  in
  match content_length with
  | Some content_length ->
    ("content-length", string_of_int content_length) :: headers
  | None -> headers

let of_binary
  ?(status=`OK)
  ?(content_type="application/octet-stream")
  ?headers
  ?cookies
  body =
  let headers = make_headers
    ?headers
    ?cookies
    ~content_length:(String.length body)
    content_type
  in
  make ~status ~headers (Body.of_string body)

let of_html ?(status=`OK) ?headers ?cookies =
  of_binary ~status ~content_type:"text/html" ?headers ?cookies

let of_json ?(status=`OK) ?headers ?cookies body = body
  |> Ezjsonm.to_string ~minify:true
  |> of_binary ~status ~content_type:"application/json" ?headers ?cookies

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

let of_text ?(status=`OK) ?headers ?cookies =
  of_binary ~status ~content_type:"text/plain" ?headers ?cookies

let of_status ?(content_type=`text) ?headers ?cookies ?message status =
  let header = H.Status.to_string status in
  match content_type with
  | `text ->
    let body = Option.fold ~none:"" ~some:((^) "\n\n") message in
    of_text ~status ?headers ?cookies ("# " ^ header ^ body)
  | `html ->
    let some message = "<p>" ^ message ^ "</p>" in
    let body = Option.fold ~none:"" ~some message in
    of_html ~status ?headers ?cookies ("<h1>" ^ header ^ "</h1>" ^ body)

let make_chunk line =
  let off = 0 in
  let len = String.length line in
  { H.IOVec.off; len; buffer = Bigstringaf.of_string ~off ~len line }

let of_view ?(status=`OK) ?(content_type="text/html") ?headers ?cookies view =
  let stream, push_to_stream = Lwt_stream.create () in
  let p string = push_to_stream (Some (make_chunk string)) in
  view p;
  push_to_stream None;

  stream
  |> Body.of_stream
  |> make ~status ~headers:(make_headers ?headers ?cookies content_type)

let of_file ?(status=`OK) ?content_type ?headers ?cookies file_name =
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
    let headers = make_headers ?headers ?cookies content_type in
    let body = Body.of_bigstring bigstring in
    make ~status ~headers body
  in
  Lwt.catch f @@ fun exn ->
    Lwt.return @@ match exn with
      | Unix.Unix_error (Unix.ENOENT, _, _) ->
        let message =
          "ReWeb.Response.of_file: file not found: " ^ file_name
        in
        of_status ~message `Not_found
      | _ -> of_status `Internal_server_error

let status { envelope = { H.Response.status; _ }; _ } = status

