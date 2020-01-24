open Alcotest
open ReWeb.Cache

module Cache = InMemory(StringKey)
module Let = ReWeb__Let

let key = "key"
let value = "value"
let cache_value = option string

let s = "ReWeb.Cache", [
  Alcotest_lwt.test_case "make, add, find_opt" `Quick begin fun _ () ->
    let cache = Cache.make () in
    let open Let.Lwt in
    let+ result = Cache.access cache begin fun table ->
      let open Cache.Table in
      add table key value;
      find_opt table key
    end
    in
    check cache_value "" (Some value) result
  end;

  Alcotest_lwt.test_case "make, add, remove, find_opt" `Quick begin fun _ () ->
    let cache = Cache.make () in
    let open Let.Lwt in
    let+ result = Cache.access cache begin fun table ->
      let open Cache.Table in
      add table key value;
      remove table key;
      find_opt table key
    end
    in
    check cache_value "" None result
  end;
]

