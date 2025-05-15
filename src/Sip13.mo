import Nat "mo:base/Nat";
import Nat8 "mo:base/Nat8";
import Nat16 "mo:base/Nat16";
import Nat32 "mo:base/Nat32";
import Nat64 "mo:base/Nat64";
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


      var v0_ = v0;
      var v1_ = v1;
      var v2_ = v2;
      var v3_ = v3;

      v3_ ^= tail;

      v0_ +%= v1_; v1_ <<>= 13; v1_ ^= v0_; v0_ <<>= 32;
      v2_ +%= v3_; v3_ <<>= 16; v3_ ^= v2_;
      v0_ +%= v3_; v3_ <<>= 21; v3_ ^= v0_;
      v2_ +%= v1_; v1_ <<>= 17; v1_ ^= v2_; v2_ <<>= 32;

      v0_ ^= tail;

      v0 := v0_;
      v1 := v1_;
      v2 := v2_;
      v3 := v3_;

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
      if (ntail == 0) {
        v3 ^= bytes;
        compress();
        v0 ^= bytes;
        length += 8;
      } else {
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
    };

    public func writeBytes(bytes: [Nat8]) {
      let size_nat = bytes.size();
      length += size_nat;
      var ix = 0;

      var v0_ = v0;
      var v1_ = v1;
      var v2_ = v2;
      var v3_ = v3;

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
          v3_ ^= tail;

          v0_ +%= v1_; v1_ <<>= 13; v1_ ^= v0_; v0_ <<>= 32;
          v2_ +%= v3_; v3_ <<>= 16; v3_ ^= v2_;
          v0_ +%= v3_; v3_ <<>= 21; v3_ ^= v0_;
          v2_ +%= v1_; v1_ <<>= 17; v1_ ^= v2_; v2_ <<>= 32;

          v0_ ^= tail;
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

        v3_ ^= block;

        v0_ +%= v1_; v1_ <<>= 13; v1_ ^= v0_; v0_ <<>= 32;
        v2_ +%= v3_; v3_ <<>= 16; v3_ ^= v2_;
        v0_ +%= v3_; v3_ <<>= 21; v3_ ^= v0_;
        v2_ +%= v1_; v1_ <<>= 17; v1_ ^= v2_; v2_ <<>= 32;

        v0_ ^= block;

        v0 := v0_;
        v1 := v1_;
        v2 := v2_;
        v3 := v3_;

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

    public func finish() : Nat64 {
        let b : Nat64 = ((Nat64.fromNat(length) & 0xff) << 56) | tail;
        var v0_ = v0;
        var v1_ = v1;
        var v2_ = v2;
        var v3_ = v3;

        v3_ ^= b;

        v0_ +%= v1_; v1_ <<>= 13; v1_ ^= v0_; v0_ <<>= 32;
        v2_ +%= v3_; v3_ <<>= 16; v3_ ^= v2_;
        v0_ +%= v3_; v3_ <<>= 21; v3_ ^= v0_;
        v2_ +%= v1_; v1_ <<>= 17; v1_ ^= v2_; v2_ <<>= 32;

        v0_ ^= b;

        v2_ ^= 0xff;

        // 3 Inlined compress rounds
        v0_ +%= v1_; v1_ <<>= 13; v1_ ^= v0_; v0_ <<>= 32;
        v2_ +%= v3_; v3_ <<>= 16; v3_ ^= v2_;
        v0_ +%= v3_; v3_ <<>= 21; v3_ ^= v0_;
        v2_ +%= v1_; v1_ <<>= 17; v1_ ^= v2_; v2_ <<>= 32;

        v0_ +%= v1_; v1_ <<>= 13; v1_ ^= v0_; v0_ <<>= 32;
        v2_ +%= v3_; v3_ <<>= 16; v3_ ^= v2_;
        v0_ +%= v3_; v3_ <<>= 21; v3_ ^= v0_;
        v2_ +%= v1_; v1_ <<>= 17; v1_ ^= v2_; v2_ <<>= 32;

        v0_ +%= v1_; v1_ <<>= 13; v1_ ^= v0_; v0_ <<>= 32;
        v2_ +%= v3_; v3_ <<>= 16; v3_ ^= v2_;
        v0_ +%= v3_; v3_ <<>= 21; v3_ ^= v0_;
        v2_ +%= v1_; v1_ <<>= 17; v1_ ^= v2_; v2_ <<>= 32;

        v0_ ^ v1_ ^ v2_ ^ v3_
    };

    func compress() {
      var v0_ = v0;
      var v1_ = v1;
      var v2_ = v2;
      var v3_ = v3;
      v0_ +%= v1_; v1_ <<>= 13; v1_ ^= v0_; v0_ <<>= 32;
      v2_ +%= v3_; v3_ <<>= 16; v3_ ^= v2_;
      v0_ +%= v3_; v3_ <<>= 21; v3_ ^= v0_;
      v2_ +%= v1_; v1_ <<>= 17; v1_ ^= v2_; v2_ <<>= 32;
      v0 := v0_;
      v1 := v1_;
      v2 := v2_;
      v3 := v3_;
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
