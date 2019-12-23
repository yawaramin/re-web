open ReWeb;

type t = {
  username: string,
  password: string,
};

let id = x => Ok(x);

open Form;

let form =
  make(
    Fields.[field("username", id), field("password", id)],
    (username, password) =>
    {username, password}
  );
