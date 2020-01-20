open Alcotest
open ReWeb.Header.ContentSecurityPolicy

let csp = "content-security-policy"
let header = pair string string

let s = "ReWeb.Header.ContentSecurityPolicy", [
  test_case "to_header - no directives" `Quick begin fun () ->
    []
    |> make
    |> to_header
    |> check header "" (csp, "default-src 'self'")
  end;

  test_case "to_header - directives" `Quick begin fun () ->
    [Self; Host "*.mailsite.com"]
    |> make ~img_src:[Host "*"]
    |> to_header
    |> check header "" (csp, "default-src 'self' *.mailsite.com; img-src *")
  end;

  test_case "to_header - report only" `Quick begin fun () ->
    [Self; Host "*.mailsite.com"]
    |> make ~img_src:[Host "*"] ~block_all_mixed_content:true
    |> to_header ~report_only:true
    |> check header "" (
        "content-security-policy-report-only",
        "default-src 'self' *.mailsite.com; img-src *; block-all-mixed-content"
      )
  end;
]

