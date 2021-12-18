let suite, exit = Junit_alcotest.run_and_report "Test" [
  CacheTest.s;
  FormTest.s;
  HeaderTest.ContentSecurityPolicyTest.s;
  HeaderTest.SetCookieTest.s;
  HeaderTest.StrictTransportSecurityTest.s;
  RequestTest.s;
  ResponseTest.s;
  TopicTest.s;
]

let junit = Junit.make [suite]

let () =
  Junit.to_file junit "junit.xml";
  exit ()
