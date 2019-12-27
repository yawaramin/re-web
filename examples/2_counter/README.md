# 2. Counter

This is a simple counter with an integer held in memory on the server. You can read the count with a GET request and increment it via a POST request.

## Running this example

Run the following from the terminal:

```shell
esy run-example examples/2_counter/Main.bc
```

Once the server is running:

1. Navigate to `http://localhost:8080/count` in your browser, you should see a value of `0` as a response.

2. In your console, send a POST request to the `increment` route:
    ```
    curl -X POST localhost:8080/increment
    ```

3. Go back to your browser and refresh the page, you should now see a `1` as a response.

## Mutation

[Mutation](https://reasonml.github.io/docs/en/mutation) is not encouraged in Reason, but for the purpose of this example we will use an escape hatch that Reason provides.

To do this, we must wrap the value in a `ref()`. To access the value we add a `^` to the end of the let-binding's name, and we use the `:=` operator for re-assignment.

```reason
/* Wrap integer in a ref context */
let count = ref(0);

/* Access the value, increment, and re-assign */
count := count^ + 1;
```
