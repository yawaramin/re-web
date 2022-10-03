module H = Httpaf
module Header = Reweb_header

type headers = (string * string) list
type status = H.Status.t
type t = H.Response.t * Eio.Flow.source

let get_headers ({ H.Response.headers; _ }, _) = headers

let set_headers headers (resp, body) = { resp with H.Response.headers }, body

let add_header ?(replace=true) ~name ~value response =
  let add = if replace then H.Headers.add else H.Headers.add_unless_exists in
  set_headers (add (get_headers response) name value) response

let add_cookie cookie =
  let (name, value) = Header.SetCookie.to_header cookie in
  add_header ~replace:false ~name ~value

let add_headers headers response = set_headers
  (H.Headers.add_list (get_headers response) headers)
  response

let add_headers_multi headers_multi response = set_headers
  (H.Headers.add_multi (get_headers response) headers_multi)
  response

let add_cookies cookies = add_headers_multi [
  "set-cookie",
  List.map
    (fun cookie -> cookie |> Header.SetCookie.to_header |> snd)
    cookies
]

let body (_, bod) = bod

let cookies response = "set-cookie"
  |> H.Headers.get_multi (get_headers response)
  |> List.filter_map Header.SetCookie.of_header

let header name response = H.Headers.get (get_headers response) name

let headers name response =
  H.Headers.get_multi (get_headers response) name

let of_flow ~status ~headers body =
  H.Response.create ~headers:(H.Headers.of_list headers) status, body

let make_headers ?(headers=[]) ?(cookies=[]) ?content_length content_type =
  let cookie_headers = List.map Header.SetCookie.to_header cookies in
  let headers = headers @ cookie_headers @ [
    "content-type", content_type;
    "server", "ReWeb";
    "x-content-type-options", "nosniff";
  ]
  in
  match content_length with
  | Some content_length ->
    ("content-length", string_of_int content_length) :: headers
  | None -> ("connection", "close") :: headers

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
  of_flow ~status ~headers (Eio.Flow.string_source body)

let of_html ?(status=`OK) ?headers ?cookies =
  of_binary ~status ~content_type:"text/html" ?headers ?cookies

let of_json ?(status=`OK) ?headers ?cookies body = body
  |> Yojson.Safe.to_string
  |> of_binary ~status ~content_type:"application/json" ?headers ?cookies

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

let of_redirect ?(content_type="text/plain") ?(body="") location =
  of_text
    ~status:`Moved_permanently
    ~headers:["location", location; "content-type", content_type]
    body

let of_file ?(status=`OK) ?content_type ?headers ?cookies ~sw path filename =
  let ( / ) = Eio.Path.( / ) in
  match Eio.Path.open_in ~sw (path / filename) with
  | flow ->
    let content_type =
      Option.value content_type ~default:(Magic_mime.lookup filename)
    in
    let headers = make_headers ?headers ?cookies content_type in
    of_flow ~status ~headers (flow :> Eio.Flow.source)
  | exception Eio.Fs.Not_found (_, _) ->
    of_status `Not_found

let status ({ H.Response.status; _ }, _) = status
let status_code response = response |> status |> H.Status.to_code
