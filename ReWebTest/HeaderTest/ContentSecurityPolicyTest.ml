open Alcotest
open ReWeb.Header.ContentSecurityPolicy

let csp = "content-security-policy"
let report_to = "report-to"

let report_uris = [
  "https://example.com/csp-endpoint";
  "https://csp.internet.com";
]

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

  test_case "to_header - report-to - endpoints" `Quick begin fun () ->
    []
    |> make ~report_to:report_uris
    |> to_header
    |> check header "" (
        csp,
        "report-to csp-endpoint; default-src 'self'; report-uri https://example.com/csp-endpoint https://csp.internet.com"
      )
  end;

  test_case "to_header - report-to - no endpoints" `Quick begin fun () ->
    []
    |> make ~report_to:[]
    |> to_header
    |> check header "" (csp, "default-src 'self'")
  end;

  test_case "report_to_header - endpoints" `Quick begin fun () ->
    []
    |> make ~report_to:report_uris
    |> report_to_header
    |> check header "" (
        report_to,
        {|{
  "group": "csp-endpoint",
  "max_age": 10886400,
  "endpoints": [{ "url": "https://example.com/csp-endpoint" }, { "url": "https://csp.internet.com" }]
}|}
      )
  end;

  test_case "report_to_header - no endpoints" `Quick begin fun () ->
    []
    |> make ~report_to:[]
    |> report_to_header
    |> check header "" (report_to, "")
  end;
]

