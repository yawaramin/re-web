module H = Httpaf

let convert_body body =
  let stream = body
    |> Piaf.Body.to_stream
    |> Lwt_stream.map @@ fun bigstring -> {
      H.IOVec.off = 0;
      len = Bigstringaf.length bigstring;
      buffer = bigstring
    }
  in
  Body.Multi stream

let convert_response { Piaf.Response.status; headers; version; _ } =
  let headers =
    headers |> Piaf.Headers.to_rev_list |> H.Headers.of_rev_list
  in
  let status = status |> Piaf.Status.to_code |> H.Status.of_code in
  H.Response.create ~version ~headers status

module Once = struct
  module C = Piaf.Client.Oneshot

  let get url =
    let open Lwt_let in
    let* result = url |> Uri.of_string |> C.get in
    match result with
    | Ok (response, body) ->
      Lwt.return {
        Response.envelope = convert_response response;
        body = convert_body body }
    | Error string -> Lwt.fail_with string
end
