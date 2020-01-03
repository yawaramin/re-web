let () = Alcotest.run "ReWebTest" [
  Form.tests;
  Request.tests;
  Response.tests;
]

