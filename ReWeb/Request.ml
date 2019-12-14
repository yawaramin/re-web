open Httpaf

type 'ctx t = {ctx : 'ctx; reqd : Reqd.t}

let make reqd = {ctx = (); reqd}

let context {ctx; _} = ctx

let header name {reqd; _} =
  let {Request.headers; _} = Reqd.request reqd in
  Headers.get headers name

let headers name {reqd; _} =
  let {Request.headers; _} = Reqd.request reqd in
  Headers.get_multi headers name
