## ReWeb - a type-safe ergonomic ReasonML web framework (WIP)

ReWeb is a web framework based on several foundations:

- The amazing work of the people behind Httpaf, H2, and others
- The core idea of 'Your server as a function' by Marius Eriksen which
  was also the idea behind Twitter's Finagle web stack
- Jasim Basheer's essay 'Rails on OCaml' which identifies the need for an
  ergonomic, Rails-like web framework that still preserves the type
  safety benefits of OCaml.

ReWeb's main concepts are:

- Services: a service is a function from a request to a promise of
  response (i.e. an asynchronous function).
- Filters: a filter is a function that takes a service as input and
  returns a service as output. It can be inserted into the 'request
  pipeline' and manipulate the request before the service finally handles
  it.
- Server: a server is a function that takes a route (pair of HTTP method
  and path list) as input and returns a service as output.
- Type-safe request pipeline: requests have a type parameter that reveals
  their 'context' i.e. some data that's stored inside them. Filters and
  services must change requests correctly and in the right order, or the
  compiler will present type errors.

## Try

You need Esy, you can install the beta using [npm](https://npmjs.com):

    $ npm install --global esy@latest

Then run the `esy` command from this project root to install and build dependencies.

    $ esy

Now you can run your editor within the environment (which also includes merlin):

    $ esy $EDITOR
    $ esy vim

Alternatively you can try [vim-reasonml](https://github.com/jordwalke/vim-reasonml)
which loads esy project environments automatically.

After you make some changes to source code, you can re-run project's build
again with the same simple `esy` command.

    $ esy

Run the included example server:

    $ esy test

Send some requests to it:

    $ curl localhost:8080/hello
    $ curl localhost:8080/auth/hello
    $ curl --user 'bob:secret' localhost:8080/auth/hello

Go to http://localhost:8080/login in your browser, etc.

Generate documentation:

    $ esy doc
    $ esy open '#{self.target_dir}/default/_doc/_html/index.html'

Shell into environment:

    $ esy shell

## Warning

ReWeb is experimental and not for production use! I am still ironing out
the API. But (imho) it looks promising for real-world usage.
