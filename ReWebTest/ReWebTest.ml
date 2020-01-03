open Alcotest

let () = run "ReWebTest" [
  Form.tests;
  Request.tests;
  Response.tests;
]

