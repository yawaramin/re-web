let html = (title, body, p) => {
  p(
    {|<!doctype html>
<html>
  <head>
    <meta charset="utf-8">
    <title>|},
  );
  title(p);
  p({|</title>
  </head>
  <body>|});
  body(p);
  p({|</body>
</html>|});
};

let login = (~rememberMe) => {
  let title = p => p("Login");
  let body = p => {
    p(
      {|<form method="post">
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
    </form>|},
    );
  };

  html(title, body);
};

let loggedIn = (~username, ~password) => {
  let title = p => p("Logged in");
  let body = p => {
    p({|<h1>Logged in</h1>
<p>Username: "|});
    p(username);
    p({|"</p>
<p>Password: "|});
    p(password);
    p({|"</p>|});
  };

  html(title, body);
};
