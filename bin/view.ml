let html title body p =
  p {|<!doctype html>
<html>
  <head>
    <meta charset="utf-8">
    <title>|};
  title p;
  p {|</title>
  </head>
  <body>
|};
  body(p);
  p {|
  </body>
</html>|}

let login ~remember_me =
  let title p = p "Log in" in
  let body p =
    p {|    <h1>Log in</h1>
    <form method="post">
      <p>
        <label for="username">Username: </label>
        <input type="text" name="username" required>
      </p>
      <p>
        <label for="password">Password: </label>
        <input type="password" name="password" required>
      </p>
      <p><input type="checkbox" checked="|};
    p (string_of_bool remember_me);
    p {|"> Remember me</input></p>
      <p><input type="submit" value="Login"></p>
    </form>|}
  in
  html title body

let logged_in ~username ~password =
  let title p = p "Logged in" in
  let body p =
    p {|    <h1>Logged in</h1>
    <p>Username: "|};
    p username;
    p {|"</p>
    <p>Password: "|};
    p password;
    p {|"</p>|}
  in
  html title body
