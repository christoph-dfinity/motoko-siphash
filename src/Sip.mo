import Nat8 "mo:base/Nat8";
import Nat16 "mo:base/Nat16";
import Nat32 "mo:base/Nat32";
import Nat64 "mo:base/Nat64";
import Blob "mo:base/Blob";

module {
  public class SipHasher13(k0 : Nat64, k1 : Nat64) {
    var length : Nat = 0;
    var v0 : Nat64 = 0x736f6d6570736575 ^ k0;
    var v1 : Nat64 = 0x646f72616e646f6d ^ k1;
    var v2 : Nat64 = 0x6c7967656e657261 ^ k0;
    var v3 : Nat64 = 0x7465646279746573 ^ k1;

    // Unprocessed bytes
    var tail : Nat64 = 0;
    // How many bytes in tail are valid
    var ntail : Nat64 = 0;

    public func reset() {
      length := 0;
      v0 := 0x736f6d6570736575 ^ k0;
      v1 := 0x646f72616e646f6d ^ k1;
      v2 := 0x6c7967656e657261 ^ k0;
      v3 := 0x7465646279746573 ^ k1;
      tail := 0;
      ntail := 0;
    };

    public func write_nat8(byte : Nat8) {
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

    public func write_nat16(bytes : Nat16) {
      let (msb, lsb) = Nat16.explode(bytes);
      write_nat8(lsb);
      write_nat8(msb);
    };

    public func write_nat32(bytes : Nat32) {
      let (b4, b3, b2, b1) = Nat32.explode(bytes);
      write_nat8(b1);
      write_nat8(b2);
      write_nat8(b3);
      write_nat8(b4);
    };

    public func write_nat64(bytes : Nat64) {
      let (b8, b7, b6, b5, b4, b3, b2, b1) = Nat64.explode(bytes);
      write_nat8(b1);
      write_nat8(b2);
      write_nat8(b3);
      write_nat8(b4);
      write_nat8(b5);
      write_nat8(b6);
      write_nat8(b7);
      write_nat8(b8);
    };

    public func write_bytes(bytes: [Nat8]) {
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

    public func write_blob(blob: Blob) {
      // TODO: Optimize
      write_bytes(Blob.toArray(blob))
    };

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

    func compress() {
      v0 +%= v1; v1 <<>= 13; v1 ^= v0; v0 <<>= 32;
      v2 +%= v3; v3 <<>= 16; v3 ^= v2;
      v0 +%= v3; v3 <<>= 21; v3 ^= v0;
      v2 +%= v1; v1 <<>= 17; v1 ^= v2; v2 <<>= 32;
    }
  };

}
