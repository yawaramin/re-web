open Alcotest
open ReWeb.Response

let name = "x"
let option_string = option string

let s = "Response", [
  test_case "add_cookie" `Quick begin fun () ->
    ""
    |> of_binary
    |> add_cookie @@ Header.SetCookie.make ~name "0"
    |> cookies
    |> List.map Header.SetCookie.to_header
    |> check (list (pair string string)) "" @@ [
      "set-cookie", "x=0; Secure; HttpOnly; SameSite=Lax"
    ]
  end;

  test_case "add_cookies" `Quick begin fun () ->
    let cookies_to_add = Header.SetCookie.[
      make ~name:"x" "0";
      make ~name:"y" "1";
    ]
    in
    ""
    |> of_binary
    |> add_cookies cookies_to_add
    |> cookies
    |> List.map Header.SetCookie.to_header
    |> check (list (pair string string)) "" @@ [
      "set-cookie", "x=0; Secure; HttpOnly; SameSite=Lax";
      "set-cookie", "y=1; Secure; HttpOnly; SameSite=Lax";
    ]
  end;

  test_case "add_header - replace" `Quick begin fun () ->
    let value = "2" in
    ""
    |> of_binary ~headers:[name, "1"]
    |> add_header ~name ~value
    |> header name
    |> check option_string "" (Some value)
  end;

  test_case "add_header - no replace" `Quick begin fun () ->
    let value = "1" in
    ""
    |> of_binary ~headers:[name, value]
    |> add_header ~replace:false ~name ~value:"2"
    |> header name
    |> check option_string "" (Some value)
  end;

  test_case "add_headers" `Quick begin fun () ->
    let response = ""
      |> of_binary ~headers:[name, "1"]
      |> add_headers [name, "2"; "y", "3"]
    in
    check option_string "" (Some "2") @@ header name response;
    check option_string "" (Some "3") @@ header "y" response
  end;

  test_case "add_headers_multi" `Quick begin fun () ->
    let values = ["1"; "2"] in
    ""
    |> of_binary
    |> add_headers_multi [name, values]
    |> headers name
    |> check (list string) "" values
  end;

  test_case "of_binary - merge content-type into headers" `Quick begin fun () ->
    let content_type = "text/plain" in
    let value = "1" in
    let response = of_binary ~content_type ~headers:[name, value] "" in

    check option_string "" (Some value) @@ header name response;
    check option_string "" (Some content_type) @@ header "content-type" response
  end;

  test_case "of_binary - merge headers and cookies" `Quick begin fun () ->
    let value = "1" in
    let cookie = ReWeb.Header.SetCookie.make
      ~secure:false
      ~http_only:false
      ~name:"y"
      "2"
    in
    let response =
      of_binary ~headers:[name, value] ~cookies:[cookie] ""
    in
    check option_string "" (Some value) @@ header name response;
    check option_string "" (Some "y=2; SameSite=Lax")
      @@ header "set-cookie" response
  end;

  test_case "of_redirect - build redirect response" `Quick begin fun () ->
    let location = "/hello" in
    let response = of_redirect location in

    check option_string "" (Some location) @@ header "location" response;
    check int "" 301 @@ status_code response
  end;
]

