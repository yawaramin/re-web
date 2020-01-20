let () = Alcotest.run "ReWebTest" [
  FormTest.s;
  HeaderTest.ContentSecurityPolicyTest.s;
  HeaderTest.SetCookieTest.s;
  HeaderTest.StrictTransportSecurityTest.s;
  RequestTest.s;
  ResponseTest.s;
]

