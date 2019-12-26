open ReWeb;

type t = {
  username: string,
  password: string,
};

let form =
  Form.(
    make(
      Field.[
        string("username"),
        // Form validation will fail if the password is 'password'
        ensure((!=)("password"), string("password")),
      ],
      (username, password) =>
      {username, password}
    )
  );
