let () = Alcotest.run "ReWebTest" [
  FormTest.s;
  HeaderTest.SetCookieTest.s;
  RequestTest.s;
  ResponseTest.s;
]

