let () = Alcotest.run "ReWebTest" [
  CacheTest.s;
  FormTest.s;
  HeaderTest.ContentSecurityPolicyTest.s;
  HeaderTest.SetCookieTest.s;
  HeaderTest.StrictTransportSecurityTest.s;
  RequestTest.s;
  ResponseTest.s;
]

