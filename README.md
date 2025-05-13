# motoko-siphash

A Motoko implementation of [SipHash](https://en.wikipedia.org/wiki/SipHash)

## Example

```motoko
import { withHasherUnkeyed } "mo:siphash/Sip";

type Vec2 = {
  x : Nat;
  y : Nat;
};

func hashVec2(vec : Vec2) : Nat64 {
  withHasherUnkeyed(func (h) {
    h.writeNat(vec.x);
    h.writeNat(vec.y);
  })
};
```

## Testing

Running the tests: `just test`

Tests are using the Rust implementation as an Oracle in `dev/main.rs`. After making changes you can regenerate them with `just test-gen`.
