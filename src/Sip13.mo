import Nat "mo:base/Nat";
import Nat8 "mo:base/Nat8";
import Nat16 "mo:base/Nat16";
import Nat32 "mo:base/Nat32";
import Nat64 "mo:base/Nat64";
import Int "mo:base/Int";
import Int8 "mo:base/Int8";
import Int16 "mo:base/Int16";
import Int32 "mo:base/Int32";
import Int64 "mo:base/Int64";
import Blob "mo:base/Blob";
import Text "mo:base/Text";
import Hasher "Hasher";

module {
  public class SipHasher13(k0 : Nat64, k1 : Nat64) {
    var v0 : Nat64 = 0x736f6d6570736575 ^ k0;
    var v1 : Nat64 = 0x646f72616e646f6d ^ k1;
    var v2 : Nat64 = 0x6c7967656e657261 ^ k0;
    var v3 : Nat64 = 0x7465646279746573 ^ k1;

    // Total written bytes
    var length : Nat = 0;
    // Unprocessed bytes
    var tail : Nat64 = 0;
    // How many bytes in tail are valid
    var ntail : Nat64 = 0;

    public func reset() {
      v0 := 0x736f6d6570736575 ^ k0;
      v1 := 0x646f72616e646f6d ^ k1;
      v2 := 0x6c7967656e657261 ^ k0;
      v3 := 0x7465646279746573 ^ k1;
      length := 0;
      tail := 0;
      ntail := 0;
    };

    public func writeNat8(byte : Nat8) {
      let x = Nat64.fromNat32(Nat32.fromNat16(Nat16.fromNat8(byte)));
      length += 1;

      let needed : Nat64 = 8 - ntail;
      tail |= x << (8 * ntail);
      if (needed > 1) {
        ntail += 1;
        return
      };

      v3 ^= tail;
      compress();
      v0 ^= tail;

      ntail := 0;
      tail := 0;
    };

    public func writeNat16(bytes : Nat16) {
      let (msb, lsb) = Nat16.explode(bytes);
      writeNat8(lsb);
      writeNat8(msb);
    };

    public func writeNat32(bytes : Nat32) {
      let (b4, b3, b2, b1) = Nat32.explode(bytes);
      writeNat8(b1);
      writeNat8(b2);
      writeNat8(b3);
      writeNat8(b4);
    };

    public func writeNat64(bytes : Nat64) {
      let (b8, b7, b6, b5, b4, b3, b2, b1) = Nat64.explode(bytes);
      writeNat8(b1);
      writeNat8(b2);
      writeNat8(b3);
      writeNat8(b4);
      writeNat8(b5);
      writeNat8(b6);
      writeNat8(b7);
      writeNat8(b8);
    };

    public func writeBytes(bytes: [Nat8]) {
      let size_nat = bytes.size();
      length += size_nat;
      var ix = 0;

      if (ntail != 0) {
        let needed = 8 - ntail;
        // We can't complete a block, so just append to tail
        while (Nat64.fromNat(ix) < needed) {
          let x = Nat64.fromNat32(Nat32.fromNat16(Nat16.fromNat8(bytes[ix])));
          tail |= x << (8 * ntail);
          ntail += 1;
          ix += 1;
        };
        if (Nat64.fromNat(length) < needed) {
          ntail += Nat64.fromNat(length);
          return
        } else {
          v3 ^= tail;
          compress();
          v0 ^= tail;
          ntail := 0;
          tail := 0;
        };
      };

      // Write as many full blocks as we can
      while ((size_nat - ix) : Nat >= 8) {
        let block : Nat64
          = (Nat64.fromNat32(Nat32.fromNat16(Nat16.fromNat8(bytes[ix    ]))) <<  0)
          | (Nat64.fromNat32(Nat32.fromNat16(Nat16.fromNat8(bytes[ix + 1]))) <<  8)
          | (Nat64.fromNat32(Nat32.fromNat16(Nat16.fromNat8(bytes[ix + 2]))) << 16)
          | (Nat64.fromNat32(Nat32.fromNat16(Nat16.fromNat8(bytes[ix + 3]))) << 24)
          | (Nat64.fromNat32(Nat32.fromNat16(Nat16.fromNat8(bytes[ix + 4]))) << 32)
          | (Nat64.fromNat32(Nat32.fromNat16(Nat16.fromNat8(bytes[ix + 5]))) << 40)
          | (Nat64.fromNat32(Nat32.fromNat16(Nat16.fromNat8(bytes[ix + 6]))) << 48)
          | (Nat64.fromNat32(Nat32.fromNat16(Nat16.fromNat8(bytes[ix + 7]))) << 56);

        v3 ^= block;
        compress();
        v0 ^= block;

        ix += 8;
      };

      // We know the remaining bytes aren't enough to fill a full block,
      // so append them to tail
      while (ix < size_nat) {
        let x = Nat64.fromNat32(Nat32.fromNat16(Nat16.fromNat8(bytes[ix])));
        ix += 1;
        tail |= x << (8 * ntail);
        ntail += 1;
      };
    };

    // Verbatim copy of writeBytes
    public func writeBytesVar(bytes: [var Nat8]) {
      let size_nat = bytes.size();
      length += size_nat;
      var ix = 0;

      if (ntail != 0) {
        let needed = 8 - ntail;
        // We can't complete a block, so just append to tail
        while (Nat64.fromNat(ix) < needed) {
          let x = Nat64.fromNat32(Nat32.fromNat16(Nat16.fromNat8(bytes[ix])));
          tail |= x << (8 * ntail);
          ntail += 1;
          ix += 1;
        };
        if (Nat64.fromNat(length) < needed) {
          ntail += Nat64.fromNat(length);
          return
        } else {
          v3 ^= tail;
          compress();
          v0 ^= tail;
          ntail := 0;
          tail := 0;
        };
      };

      // Write as many full blocks as we can
      while ((size_nat - ix) : Nat >= 8) {
        let block : Nat64
          = (Nat64.fromNat32(Nat32.fromNat16(Nat16.fromNat8(bytes[ix    ]))) <<  0)
          | (Nat64.fromNat32(Nat32.fromNat16(Nat16.fromNat8(bytes[ix + 1]))) <<  8)
          | (Nat64.fromNat32(Nat32.fromNat16(Nat16.fromNat8(bytes[ix + 2]))) << 16)
          | (Nat64.fromNat32(Nat32.fromNat16(Nat16.fromNat8(bytes[ix + 3]))) << 24)
          | (Nat64.fromNat32(Nat32.fromNat16(Nat16.fromNat8(bytes[ix + 4]))) << 32)
          | (Nat64.fromNat32(Nat32.fromNat16(Nat16.fromNat8(bytes[ix + 5]))) << 40)
          | (Nat64.fromNat32(Nat32.fromNat16(Nat16.fromNat8(bytes[ix + 6]))) << 48)
          | (Nat64.fromNat32(Nat32.fromNat16(Nat16.fromNat8(bytes[ix + 7]))) << 56);

        v3 ^= block;
        compress();
        v0 ^= block;

        ix += 8;
      };

      // We know the remaining bytes aren't enough to fill a full block,
      // so append them to tail
      while (ix < size_nat) {
        let x = Nat64.fromNat32(Nat32.fromNat16(Nat16.fromNat8(bytes[ix])));
        ix += 1;
        tail |= x << (8 * ntail);
        ntail += 1;
      };
    };


    public func writeBlob(blob: Blob) {
      // TODO: Optimize
      writeBytes(Blob.toArray(blob))
    };

    public func writeText(text: Text) {
      // TODO: Optimize
      writeBlob(Text.encodeUtf8(text))
    };

    // TODO: Inline
    public func finish() : Nat64 {
        let b : Nat64 = ((Nat64.fromNat(length) & 0xff) << 56) | tail;

        v3 ^= b;
        compress();
        v0 ^= b;

        v2 ^= 0xff;
        compress();
        compress();
        compress();

        v0 ^ v1 ^ v2 ^ v3
    };

    // TODO: Inline
    func compress() {
      v0 +%= v1; v1 <<>= 13; v1 ^= v0; v0 <<>= 32;
      v2 +%= v3; v3 <<>= 16; v3 ^= v2;
      v0 +%= v3; v3 <<>= 21; v3 ^= v0;
      v2 +%= v1; v1 <<>= 17; v1 ^= v2; v2 <<>= 32;
    };
  };

  public func withHasher(k1 : Nat64, k2 : Nat64, f : Hasher.Hasher -> ()) : Nat64 {
    let hasher = SipHasher13(k1, k2);
    f(hasher);
    hasher.finish();
  };

  public func withHasherUnkeyed(f : Hasher.Hasher -> ()) : Nat64 {
    let hasher = SipHasher13(0, 0);
    f(hasher);
    hasher.finish();
  };
}
