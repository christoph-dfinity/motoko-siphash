default: test

test:
    rm -rf Test.wasm
    $(vessel bin)/moc $(vessel sources) test/Test.mo -wasi-system-api
    wasmtime Test.wasm

test-gen:
    cd dev/ && cargo run

check:
    $(vessel bin)/moc --check $(vessel sources) src/*.mo test/*.mo
