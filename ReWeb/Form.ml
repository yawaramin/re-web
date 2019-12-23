type 'a decoder = string -> ('a, string) result
type 'a field = { name : string; decoder : 'a decoder }

module Fields = struct
  type (_, _) t =
  | [] : ('a, 'a) t
  | (::) : 'a field * ('b, 'c) t -> ('a -> 'b, 'c) t
end

type ('ctor, 'ty) t = { fields : ('ctor, 'ty) Fields.t; ctor : 'ctor }

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
    let open Fields in
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

let field name decoder = { name; decoder }
let make fields ctor = { fields; ctor }
