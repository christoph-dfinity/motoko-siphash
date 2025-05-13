default: test

test:
    rm -rf Test.test.wasm
    $(vessel bin)/moc $(vessel sources) test/Test.test.mo -wasi-system-api
    wasmtime Test.test.wasm

test-gen:
    cd dev/ && cargo run

check:
    $(vessel bin)/moc --check $(vessel sources) src/*.mo test/*.mo
