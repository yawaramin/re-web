(** ReWeb applications are configured using the {!ReWeb.Config} module.
    This module defines:

    - Functions for reading environment variables in a type-safe way
    - A module type that defines ReWeb's known config settings
    - A module that defines the default values of these settings

    This last module, {!ReWeb.Config.Default}, is injected into the
    major parts of ReWeb and is accessible from them. You can configure
    a ReWeb application in two ways:

    {1 Setting environment variables}

    You can run a ReWeb application after setting environment variables
    it knows about. See {!ReWeb.Config.S} for the exact ones. For
    example:

    {[$ REWEB__buf_size=2048 esy x dune exec bin/App.exe]}

    This configures the internal buffer size used for building strings
    from request bodies.

    {1 Overriding the configuration module}

    This is a more complex method of overriding configuration that's
    really only meant for testing, because it doesn't work for actually
    running a server. For testing purposes, you can create your own
    config module that {i conforms} to ReWeb's configuration module
    type:

    {[module MyConfig = {
        let buf_size = 2_048;
      };]}

    Then, you can inject it into the main ReWeb modules that handle
    requests, services, and filters. See [ReWebTest.Request] for a
    concrete example of this. *)

