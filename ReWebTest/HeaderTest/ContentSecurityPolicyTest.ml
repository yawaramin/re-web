open Alcotest
open ReWeb.Header.ContentSecurityPolicy

let csp = "content-security-policy"
let header = pair string string

let s = "ReWeb.Header.ContentSecurityPolicy", [
  test_case "to_header - no directives" `Quick begin fun () ->
    []
    |> to_header
    |> check header "" (csp, "default-src 'self'")
  end;

  test_case "to_header - directives" `Quick begin fun () ->
    [Default_src [Self; Host "*.mailsite.com"]; Img_src [Host "*"]]
    |> to_header
    |> check header "" (csp, "default-src 'self' *.mailsite.com; img-src *")
  end;

  test_case "to_header - report only" `Quick begin fun () ->
    [
      Default_src [Self; Host "*.mailsite.com"];
      Img_src [Host "*"];
      Block_all_mixed_content;
    ]
    |> to_header ~report_only:true
    |> check header "" (
        "content-security-policy-report-only",
        "default-src 'self' *.mailsite.com; img-src *; block-all-mixed-content"
      )
  end;
]

