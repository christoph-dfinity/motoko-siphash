let upstream = https://github.com/dfinity/vessel-package-set/releases/download/mo-0.14.9-20250428/package-set.dhall sha256:8cc22bdda29dd198f1a8519a6d7b14a586977dc26492e74bee44929ad58a68fb
let Package =
    { name : Text, version : Text, repo : Text, dependencies : List Text }

let
  additions =
    [ { name = "core"
      , version = "preview-0.5.0"
      , repo = "https://github.com/dfinity/motoko-core"
      , dependencies = [] : List Text
      }
    ] : List Package

in  upstream # additions
