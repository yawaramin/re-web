module H = Httpaf

let convert_response { Piaf.Response.status; headers; version; _ } =
  let headers =
    headers |> Piaf.Headers.to_rev_list |> H.Headers.of_rev_list
  in
  let status = status |> Piaf.Status.to_code |> H.Status.of_code in
  H.Response.create ~version ~headers status

module Once = struct
  module Client = Piaf.Client.Oneshot

  let get url =
    let open Lwt_let in
    let+ result = url |> Uri.of_string |> Client.get in
    let open Result_let in
    let+ response, body = result in
    {
      Response.envelope = convert_response response;
      body = Body.Piaf body
    }
end

