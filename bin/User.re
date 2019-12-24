open ReWeb;

type t = {
  username: string,
  password: string,
};

let form =
  Form.(
    make(
      Field.[string("username"), string("password")], (username, password) =>
      {username, password}
    )
  );
