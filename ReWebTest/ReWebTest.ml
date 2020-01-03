open Alcotest

let () = run "ReWebTest" [
  Form.tests;
  Response.tests;
]

