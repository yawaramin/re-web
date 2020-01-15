open Alcotest
open ReWeb.Header.SetCookie

let cookie_name = "c"
let option_string = option string

let s = "SetCookie", [
  test_case "make - constructs all directives" `Quick begin fun () ->
    "0"
    |> make
      ~max_age:0
      ~secure:true
      ~http_only:true
      ~domain:"localhost"
      ~path:"/api"
      ~same_site:Strict
      ~name:cookie_name
    |> value
    |> check string "" "c=0; Max-Age=0; Secure; HttpOnly; Domain=localhost; Path=/api; SameSite=Strict"
  end;

  test_case "make - omits directives" `Quick begin fun () ->
    "0"
    |> make
      ~secure:false
      ~http_only:true
      ~same_site:Strict
      ~name:cookie_name
    |> value
    |> check string "" "c=0; HttpOnly; SameSite=Strict"
  end;

  test_case "of_header - parses header value into cookie" `Quick begin fun () ->
    let cookie = of_header "c=0" in
    check option_string "name" (Some cookie_name) @@ Option.map name cookie;
    check option_string "value" (Some "0") @@ Option.map value cookie
  end;

  test_case "of_header - fails to parse malformed header" `Quick begin fun () ->
    let cookie = of_header cookie_name in
    check option_string "name" None @@ Option.map name cookie;
    check option_string "value" None @@ Option.map value cookie
  end;
]

