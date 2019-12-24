type 'a decoder = string -> ('a, string) result

module Field = struct
  type 'a t = { name : string; decoder : 'a decoder }

  type (_, _) list =
  | [] : ('a, 'a) list
  | (::) : 'a t * ('b, 'c) list -> ('a -> 'b, 'c) list

  let make name decoder = { name; decoder }

  let bool name = make name @@ fun x ->
    try Ok (bool_of_string x)
    with _ -> Error ("ReWeb.Form.Field.bool: " ^ name)

  let float name = make name @@ fun x ->
    try Ok (float_of_string x)
    with _ -> Error ("ReWeb.Form.Field.float: " ^ name)

  let int name = make name @@ fun x ->
    try Ok (int_of_string x)
    with _ -> Error ("ReWeb.Form.Field.int: " ^ name)

  let string name = make name @@ fun x -> Ok x
end

type ('ctor, 'ty) t = { fields : ('ctor, 'ty) Field.list; ctor : 'ctor }

let split_values kvp = match String.split_on_char '=' kvp with
  | [k; v] -> Some (k, v)
  | _ -> None

let split_fields string = string
  |> String.split_on_char '&'
  |> List.filter_map split_values

let rec decode :
  type ctor ty.
  (ctor, ty) t ->
  (string * string) list ->
  (ty, string) result =
  fun { fields; ctor } fields_assoc ->
    let open Field in
    match fields with
    | [] -> Ok ctor
    | field :: fields ->
      begin match List.assoc field.name fields_assoc with
      | value ->
        begin match field.decoder value with
        | Ok value ->
          begin match ctor value with
          | ctor -> decode { fields; ctor } fields_assoc
          | exception _ ->
            Error ("ReWeb.Form.decoder: could not decode value for key " ^ field.name)
          end
        | Error string -> Error string
        end
      | exception Not_found ->
        Error ("ReWeb.Form.decoder: could not find key " ^ field.name)
      end

let decoder form string = string |> split_fields |> decode form
let make fields ctor = { fields; ctor }
