open ReWeb.Response

let%test "add_header - replace" =
  let name = "x" in
  ""
  |> of_binary ~headers:[name, "1"]
  |> add_header ~name ~value:"2"
  |> header name
  |> ((=) (Some "2"))

let%test "add_header - no replace" =
  let name = "x" in
  ""
  |> of_binary ~headers:[name, "1"]
  |> add_header ~replace:false ~name ~value:"2"
  |> header name
  |> ((=) (Some "1"))

let%test "add_headers" =
  let name = "x" in
  let response = ""
    |> of_binary ~headers:[name, "1"]
    |> add_headers ["x", "2"; "y", "3"]
  in
  (header name response, header "y" response) = (Some "2", Some "3")

let%test "add_headers_multi" =
  let name = "x" in
  ""
  |> of_binary
  |> add_headers_multi [name, ["1"; "2"]]
  |> headers name
  |> ((=) ["1"; "2"])

let%test "of_binary - merge content-type into headers" =
  let response =
    of_binary ~content_type:"text/plain" ~headers:["x", "1"] ""
  in
  (header "x" response, header "content-type" response) = (Some "1", Some "text/plain")

let%test "of_binary - merge headers and cookies" =
  let response = of_binary ~headers:["x", "1"] ~cookies:["y", "2"] "" in
  (header "x" response, header "set-cookie" response) = (Some "1", Some "y=2")

let%test "of_redirect - build redirect response" =
  let response = of_redirect "/hello" in
  (header "location" response, status response) = (Some "/hello", `Moved_permanently)

