## ReWeb - a type-safe ergonomic ReasonML and OCaml web framework (WIP)

[![Build Status](https://dev.azure.com/yawaramin/re-web/_apis/build/status/yawaramin.re-web?branchName=main)](https://dev.azure.com/yawaramin/re-web/_build/latest?definitionId=1?branchName=main)
[![Test Status](https://img.shields.io/azure-devops/tests/yawaramin/re-web/1?compact_message)](https://dev.azure.com/yawaramin/re-web/_test/analytics?definitionId=1&contextType=build)

ReWeb is a web framework based on several foundations:

- The amazing work of the people behind
  [Httpaf](https://github.com/inhabitedtype/httpaf),
  [H2](https://github.com/anmonteiro/ocaml-h2), [Esy](https://esy.sh/),
  and others
- The core idea of
  ['Your server as a function'](https://monkey.org/~marius/funsrv.pdf)
  by Marius Eriksen which was also the idea behind Twitter's Finagle web
  stack
- Jasim Basheer's essay
  ['Rails on OCaml'](https://protoship.io/blog/rails-on-ocaml/) which
  identifies the need for an ergonomic, Rails-like web framework that
  still preserves the type safety benefits of OCaml.

ReWeb's main concepts are:

- Services: a service is a function from a request to a promise of
  response (i.e. an asynchronous function).
- Filters: a filter is a function that takes a service as input and
  returns a service as output. It can be inserted into the 'request
  pipeline' and manipulate the request before the service finally
  handles it.
- Server: a server is a function that takes a route (pair of HTTP method
  and path list) as input and returns a service as output.
- Type-safe request pipeline: requests have a type parameter that
  reveals their 'context' i.e. some data that's stored inside them.
  Filters and services must change requests correctly and in the right
  order, or the compiler will present type errors.

Notice that all the main concepts here are just functions. They are all
composeable using just function composition. Services can call other
services. Filters can slot together by calling each other. Servers can
delegate smaller scopes to other servers. See `bin/Main.re` for examples
of all of these.

## Documentation

- [API Reference](https://yawaramin.github.io/re-web/re-web/ReWeb/index.html)
- [User's Manual](https://yawaramin.github.io/re-web/re-web/Manual/index.html)

## Examples

### Fullstack Reason

Check out the demo repo which shows a fullstack Reason setup with ReWeb
and ReasonReact, with code sharing:
https://github.com/yawaramin/fullstack-reason/

This repo can be cloned and used right away for a new project.

### Examples directory

Check out the `examples/` directory for small, self-contained basic
examples.

### Bin directory

Finally, check out the example server in the `bin/` directory. The
`Main.re` file there has extensive examples of almost everything ReWeb
currently supports.

Run the example server:

    $ esy bin

Send some requests to it:

    $ curl localhost:8080/hello
    $ curl localhost:8080/auth/hello
    $ curl --user 'bob:secret' localhost:8080/auth/hello

Go to http://localhost:8080/login in your browser, etc.

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

Generate documentation:

    $ esy doc
    $ esy open '#{self.target_dir}/default/_doc/_html/index.html'

Shell into environment:

    $ esy shell

Run the test suite with:

    $ esy test

## Warning

ReWeb is experimental and not for production use! I am still ironing out
the API. But (imho) it looks promising for real-world usage.
