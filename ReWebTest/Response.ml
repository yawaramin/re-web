open ReWeb.Response

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

