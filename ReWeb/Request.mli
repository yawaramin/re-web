type 'ctx t = {ctx : 'ctx; reqd : Httpaf.Reqd.t}

val make : Httpaf.Reqd.t -> unit t
