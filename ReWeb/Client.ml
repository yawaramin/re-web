module H = Httpaf

type headers = (string * string) list

let convert_response result =
  let open Let.Result in
  let+ { Piaf.Response.status; headers; version; _ }, body = result in
  let headers =
    headers |> Piaf.Headers.to_rev_list |> H.Headers.of_rev_list
  in
  let status = status |> Piaf.Status.to_code |> H.Status.of_code in
  let envelope = H.Response.create ~version ~headers status in {
    Response.envelope;
    body = Body.Piaf body;
  }

module New = struct
  module Client = Piaf.Client.Oneshot

  type request_body =
    ?config:Piaf.Config.t ->
    ?headers:(string * string) list ->
    ?body:Body.t ->
    string ->
    (Response.t, string) Lwt_result.t

  type request_nobody =
    ?config:Piaf.Config.t ->
    ?headers:(string * string) list ->
    string ->
    (Response.t, string) Lwt_result.t

  let request_nobody ?config ?headers meth url = url
    |> Uri.of_string
    |> meth ?config ?headers
    |> Lwt.map convert_response

  let request_body ?config ?headers ?body meth url =
    let body = Option.map Body.to_piaf body in
    url
    |> Uri.of_string
    |> meth ?config ?headers ?body
    |> Lwt.map convert_response

  let delete ?config ?headers ?body url =
    request_body ?config ?headers ?body Client.delete url

  let get ?config ?headers url =
    request_nobody ?config ?headers Client.get url

  let head ?config ?headers url =
    request_nobody ?config ?headers Client.head url

  let patch ?config ?headers ?body url =
    request_body ?config ?headers ?body Client.patch url

  let post ?config ?headers ?body url =
    request_body ?config ?headers ?body Client.post url

  let put ?config ?headers ?body url =
    request_body ?config ?headers ?body Client.put url

  let request ?config ?headers ?body ~meth url =
    let body = Option.map Body.to_piaf body in
    url
    |> Uri.of_string
    |> Client.request ?config ?headers ?body ~meth
    |> Lwt.map convert_response
end

