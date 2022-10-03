let to_sink writer : Eio.Flow.sink = object
  inherit Eio.Flow.sink

  method copy src =
    let buf = Cstruct.create Reweb_cfg.buf_size in
    try
      while true do
        let got = src#read_into buf in
        Httpaf.Body.write_bigstring writer ~len:got buf.buffer
      done
    with End_of_file -> Httpaf.Body.close_writer writer
end
