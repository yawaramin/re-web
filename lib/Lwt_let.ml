let (let*) = Lwt.bind
let (let+) lwt f = Lwt.map f lwt
