open Alcotest
open ReWeb.Header.StrictTransportSecurity

let s = "ReWeb.Header.StrictTransportSecurity", [
  test_case "make - defaults" `Quick begin fun () ->
    100_000
    |> make
    |> to_header
    |> snd
    |> check string "" "max-age=100000; includeSubDomains; preload"
  end;
]

