let login = (~rememberMe, p) => {
  p(
    {|<!doctype html>
<html>
  <head>
    <meta charset="utf-8">
    <title>Login</title>
  </head>
  <body>
    <form method="post">
      <label for="username">Username: </label>
      <input type="text" name="username" required>
      <label for="password">Password: </label>
      <input type="text" name="password" required>
      <input type="checkbox" checked="|},
  );
  p(string_of_bool(rememberMe));
  p(
    {|"> Remember me</input>
      <input type="submit" value="Login">
    </form>
  </body>
</html>|},
  );
};
