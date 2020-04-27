open Alcotest
open ReWeb.Cache

module Cache = InMemory(StringKey)

let key = "key"
let value = "value"
let cache_value = option string

let s = "ReWeb.Cache", [
  Alcotest_lwt.test_case "make, add, find_opt" `Quick begin fun _ () ->
    let cache = Cache.make () in
    let open Lwt.Syntax in
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
    let open Lwt.Syntax in
    let+ result = Cache.access cache begin fun table ->
      let open Cache.Table in
      add table key value;
      remove table key;
      find_opt table key
    end
    in
    check cache_value "" None result
  end;

  Alcotest_lwt.test_case "concurrent operations are serialized" `Slow begin fun _ () ->
    let cache = Cache.make () in
    let open Lwt.Syntax in
    let* () = Cache.add cache ~key value in

    (* Start this access thread concurrently *)
    let thread1 = Cache.access cache begin fun table ->
      Unix.sleep 1;
      Cache.Table.find_opt table key
    end
    in

    (* Wait for key-value to be removed from cache *)
    let* () = Cache.remove cache ~key in

    (* Wait for cache access thread to finish *)
    let+ result = thread1 in

    (* Since the cache access started first, it should have taken the
       lock on the cache and found the value *)
    check cache_value "" (Some value) result
  end;
]

