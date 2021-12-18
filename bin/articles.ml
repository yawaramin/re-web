(* Partial example of setting up a resource, see bottom of file for the
   overall routes. *)

open ReWeb

(* The type of an article *)
type t = { id : int; name : string }

(* Need to know the scope to render links in views *)
let scope = "/articles"

(* Form for creating a new article *)
let create_form =
  let open Form in
  make Field.[int "id"; string "name"] @@ fun id name -> { id; name }

(* Rendering article pages *)
module View = struct
  let back_to_articles p =
    p {|<p><a href="|};
    p scope;
    p {|"><- Back to Articles</a></p>|}

  let article ~id ~name p =
    let id = string_of_int id in

    p {|<article><h2>|};
    p name;
    p {|</h2><p><a href="|};
    p scope;
    p {|/|};
    p id;
    p {|">#|};
    p id;
    p {|</a></p></article>|}

  let articles ~list =
    let title p = p "Articles" in
    let body p =
      p {|<h1>Articles</h1>|};
      List.iter (fun { id; name } -> article ~id ~name p) list;
      p {|<p><a href="|};
      p scope;
      p {|/new">New</a></p>|}
    in
    View.html title body

  let new_article =
    let title p = p "New Article" in
    let body p =
      back_to_articles p;
      p {|<h1>New Article</h1>
  <form method="POST" enctype="multipart/form-data" action="|};
      p scope;
      p {|">
    <p>
      <label for="id">ID: </label>
      <input type="number" name="id" required>
    </p>
    <p>
      <label for="name">Name: </label>
      <input type="text" name="name" required>
    </p>
    <p>
      <label for="banner">Banner: </label>
      <input type="file" name="banner">
    </p>
    <p><input type="submit" value="Create"></p>
  </form>|}
    in
    View.html title body

  (* Note that this shadows the previous binding of [article] *)
  let article ~id ~name =
    let title p =
      p {|Article: |};
      p name
    in
    let body p =
      back_to_articles p;
      (* This calls out to the previous binding of [article] *)
      article ~id ~name p
    in
    View.html title body
end

(* Start with an empty list of articles *)
let all = ref []

(* Service to show all articles *)
let index _ = View.articles ~list:!all |> Response.of_view |> Lwt.return

(* Service to create a new article *)
let create request =
  all := Request.context(request) :: !all;
  index request

(* Service to show a form for creating a new article *)
let new_ _ = View.new_article |> Response.of_view |> Lwt.return

(* Helper that gives you a service that can render a view for an ID *)
let view_id view id _ =
  Lwt.return @@ match List.find (fun { id = id2; _ } -> id2 = int_of_string id) !all with
    | { id; name } -> Response.of_view @@ view ~id ~name
    | exception Not_found -> Response.of_status `Not_found
    | exception Failure message -> Response.of_status ~message `Bad_request

let ten_minutes = 600

let show id =
  Filter.cache_control (ReWeb__Header.CacheControl.public ~max_age:ten_minutes ())
  @@ view_id View.article id

(* Due to the value restriction in OCaml we write the resource as a
   function with a positional parameter. *)
let resource route = Server.resource
  ~index
  ~create:(Filter.multipart_form ~typ:create_form (fun ~filename:_ _ ->
    "/tmp/banner")
    @@ create)
  ~new_
  ~show
  route
