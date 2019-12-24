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
      <p>
        <label for="username">Username: </label>
        <input type="text" name="username" required>
      </p>
      <p>
        <label for="password">Password: </label>
        <input type="password" name="password" required>
      </p>
      <p><input type="checkbox" checked="|},
  );
  p(string_of_bool(rememberMe));
  p(
    {|"> Remember me</input></p>
      <p><input type="submit" value="Login"></p>
    </form>
  </body>
</html>|},
  );
};

