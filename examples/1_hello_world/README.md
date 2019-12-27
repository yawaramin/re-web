# 1. Hello World

This is an example of the simplest server you can write with ReWeb.

## Running this example

To run this example, run the `ex1` script (located in `package.json`) from the terminal:

```shell
esy ex1
```

## The `|>` operator

Note that the pipe-last operator (`|>`) simply passes the result of the left expression to the function on the right (as the last argument).

That means that this:

```reason
let hello = _ => "Hello, World!" |> Response.of_text |> Lwt.return;
```

Is equivalent to this:

```reason
let hello = _ => Lwt.return(Response.of_text("Hello, World!"));
```
