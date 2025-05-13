import Array "mo:new-base/Array";
import Blob "mo:new-base/Blob";
import Text "mo:new-base/Text";
import Random "mo:new-base/Random";
import Prim "mo:prim";
import Bench "mo:bench";
import Sip13 "../src/Sip13";

module {
  public func init() : Bench.Bench {
    let bench = Bench.Bench();

    bench.name("Sip13");
    bench.description("Hash various message lengths from different types of input. Blocks are 64 bytes.");

    let rows = [
      "fromBlob",
      "fromArray",
      "fromIter",
    ];
    let cols = [
      "0",
      "1k blocks",
      "1M bytes",
    ];

    bench.rows(rows);
    bench.cols(cols);

    let rng : Random.Random = Random.fast(0x5f5f5f5f5f5f5f5f);

    let rowSourceArrays : [[Nat8]] = [
      [],
      Array.tabulate<Nat8>(64_000, func(i) = rng.nat8()),
      Array.tabulate<Nat8>(1_000_000, func(i) = rng.nat8()),
    ];

    let routines : [() -> ()] = Array.tabulate<() -> ()>(
      rows.size() * cols.size(),
      func(i) {
        let row : Nat = i % rows.size();
        let col : Nat = i / rows.size();

        let source = rowSourceArrays[col];

        switch (row) {
          case (0) {
            let blob = Blob.fromArray(source);
            func () = do {
              let hasher = Sip13.SipHasher13(0, 0);
              hasher.writeBlob(blob);
              ignore hasher.finish();
            }
          };
          case (1) {
            func () = do {
              let hasher = Sip13.SipHasher13(0, 0);
              hasher.writeBytes(source);
              ignore hasher.finish();
            }
          };
          case (2) {
            var itemsLeft = source.size();
            let iter = {
              next = func() : ?Nat8 = if (itemsLeft == 0) { null } else {
                itemsLeft -= 1;
                ?0x5f;
              };
            };
            func() = do {
              let hasher = Sip13.SipHasher13(0, 0);
              for (byte in iter) {
                hasher.writeNat8(byte);
              };
              ignore hasher.finish()
            };
          };
          case (_) Prim.trap("Row not implemented");
        };
      },
    );

    bench.runner(
      func(row, col) {
        let ?ri = Array.indexOf<Text>(row, rows, Text.equal) else Prim.trap("Unknown row");
        let ?ci = Array.indexOf<Text>(col, cols, Text.equal) else Prim.trap("Unknown column");
        routines[ci * rows.size() + ri]();
      }
    );

    bench;
  };
};
