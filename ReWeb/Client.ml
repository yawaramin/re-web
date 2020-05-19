module H = Httpaf

type config = Piaf.Config.t = {
  follow_redirects : bool;
  max_redirects : int;
  allow_insecure : bool;
  max_http_version : Piaf.Versions.HTTP.t;
  h2c_upgrade : bool;
  http2_prior_knowledge : bool;
  cacert : string option;
  capath : string option;
  min_tls_version : Piaf.Versions.TLS.t;
  max_tls_version : Piaf.Versions.TLS.t;
  tcp_nodelay : bool;
  connect_timeout : float;
  buffer_size : int;
  body_buffer_size : int;
  enable_http2_server_push : bool;
}

type headers = (string * string) list

let config = Piaf.Config.default

let convert_response = function
  | Ok { Piaf.Response.status; headers; body; _ } ->
    let status = status |> Piaf.Status.to_code |> H.Status.of_code in
    let headers = Piaf.Headers.to_list headers in
    Ok (Response.of_http ~status ~headers body)
  | Error error -> Error (Piaf.Error.to_string error)

module New = struct
  module Client = Piaf.Client.Oneshot

  type 'resp request_body =
    ?config:config ->
    ?headers:headers ->
    ?body:Piaf.Body.t ->
    string ->
    ([> Response.http] as 'resp, string) Lwt_result.t

  type 'resp request_nobody =
    ?config:config ->
    ?headers:headers ->
    string ->
    ([> Response.http] as 'resp, string) Lwt_result.t

  let request_nobody ?config ?headers meth url = url
    |> Uri.of_string
    |> meth ?config ?headers
    |> Lwt.map convert_response

  let request_body ?config ?headers ?body meth url = url
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

  let request ?config ?headers ?body ~meth url = url
    |> Uri.of_string
    |> Client.request ?config ?headers ?body ~meth
    |> Lwt.map convert_response
end

