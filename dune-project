(lang dune 3.4)

(name reweb)
(version v0.9.0)
(generate_opam_files true)
(license MIT)
(authors "Yawar Amin <yawar.amin@gmail.com>")
(maintainers "Yawar Amin <yawar.amin@gmail.com>")
(source (github yawaramin/re-web))

(package
  (name reweb)
  (synopsis "Experimental web framework for ReasonML & OCaml")
  (description "Experimental web framework for ReasonML & OCaml")
  (documentation "https://github.com/yawaramin/re-web")
  (depends
    angstrom
    (base64 (and (>= 3.5.0) (< 4.0.0)))
    (digestif (and (>= 1.1.2) (< 2.0.0)))
    (eio (and (>= 0.5) (< 1.0)))
    httpaf
    httpaf-eio
    (magic-mime (and (>= 1.2.0) (< 2.0.0)))
    (ocaml (>= 5.0.0))
    (uri (and (>= 4.2.0) (< 5.0.0)))
    (yojson (and (>= 2.0.2) (< 3.0.0)))))
