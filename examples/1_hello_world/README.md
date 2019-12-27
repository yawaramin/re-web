# 1. Hello World

This is an example of the simplest server you can write with ReWeb.

## Running this example

To run this example, run the `ex1` script (located in `package.json`) from the terminal:

```shell
esy run-example examples/1_hello_world/Main.bc
```

## The `|>` operator

The pipe-last operator (`|>`) simply passes the result of the left expression to the function on the right (as the last argument).

That means that this:

```reason
let hello = _ => "Hello, World!" |> Response.of_text |> Lwt.return;
```

Is equivalent to this:

```reason
let hello = _ => Lwt.return(Response.of_text("Hello, World!"));
```

## `Lwt`

[Lwt](https://github.com/ocsigen/lwt) is a library that facilitates asynchronous programming in Reason, and operates similar in nature to promises in [Javascript](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Promise).

`Lwt.return` wraps the passed-in argument in a promise, and satisfies the return type required for each route-handling service.
