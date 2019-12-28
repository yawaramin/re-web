open ReWeb.Response

let%test "add_header - replace" =
  let name = "x" in
  let response = ""
    |> of_binary ~headers:[name, "1"]
    |> add_header ~name ~value:"2"
    |> header name
  in
  match response with
  | Some "2" -> true
  | _ -> false

let%test "add_header - no replace" =
  let name = "x" in
  let response = ""
    |> of_binary ~headers:[name, "1"]
    |> add_header ~replace:false ~name ~value:"2"
    |> header name
  in
  match response with
  | Some "1" -> true
  | _ -> false

let%test "add_headers" =
  let name = "x" in
  let response = ""
    |> of_binary ~headers:[name, "1"]
    |> add_headers ["x", "2"; "y", "3"]
  in
  match header name response, header "y" response with
  | Some "2", Some "3" -> true
  | _ -> false

let%test "add_headers_multi" =
  let name = "x" in
  let values = ""
    |> of_binary
    |> add_headers_multi [name, ["1"; "2"]]
    |> headers name
  in
  values = ["1"; "2"]

let%test "of_binary - merge content-type into headers" =
  let response =
    of_binary ~content_type:"text/plain" ~headers:["x", "1"] ""
  in
  match header "x" response, header "content-type" response with
  | Some "1", Some "text/plain" -> true
  | _ -> false

let%test "of_binary - merge headers and cookies" =
  let response = of_binary ~headers:["x", "1"] ~cookies:["y", "2"] "" in
  match header "x" response, header "set-cookie" response with
  | Some "1", Some "y=2" -> true
  | _ -> false

let%test "of_redirect - build redirect response" =
  let response = of_redirect "/hello" in
  match header "location" response, status response with
  | Some "/hello", `Moved_permanently -> true
  | _ -> false

