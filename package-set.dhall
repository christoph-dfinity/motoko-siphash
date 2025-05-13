let upstream = https://github.com/dfinity/vessel-package-set/releases/download/mo-0.14.9-20250428/package-set.dhall sha256:8cc22bdda29dd198f1a8519a6d7b14a586977dc26492e74bee44929ad58a68fb
let Package =
    { name : Text, version : Text, repo : Text, dependencies : List Text }

let
  additions =
    [ { name = "new-base"
      , version = "1c362a913315580938dc4462bf87148b06a6095d"
      , repo = "https://github.com/dfinity/new-motoko-base"
      , dependencies = [] : List Text
      }
    , { name = "base"
      , version = "moc-0.14.10"
      , repo = "https://github.com/dfinity/motoko-base"
      , dependencies = [] : List Text
      }
    ] : List Package

in  upstream # additions
