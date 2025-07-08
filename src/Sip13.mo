import Int "mo:base/Int";
import Nat "mo:base/Nat";
import Nat8 "mo:base/Nat8";
import Nat16 "mo:base/Nat16";
import Nat32 "mo:base/Nat32";
import Nat64 "mo:base/Nat64";
import Blob "mo:base/Blob";
import Text "mo:base/Text";
import Hasher "Hasher";

module {
  // Might be a way to reduce allocations
  //
  // public type State = [var Nat64];
  // let V0 = 0;
  // let V1 = 1;
  // let V2 = 2;
  // let V3 = 3;
  // let LENGTH = 4;
  // let TAIL = 5;
  // let NTAIL = 6;

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
      let x = Nat64.fromNat(Nat8.toNat(byte));
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
      // Optimization: Writing a block aligned Nat64 means we can immediately compress
      if (ntail == 0) {
        length += 8;

        var v0_ = v0;
        var v1_ = v1;
        var v2_ = v2;
        var v3_ = v3;

        v3_ ^= bytes;

        v0_ +%= v1_; v1_ <<>= 13; v1_ ^= v0_; v0_ <<>= 32;
        v2_ +%= v3_; v3_ <<>= 16; v3_ ^= v2_;
        v0_ +%= v3_; v3_ <<>= 21; v3_ ^= v0_;
        v2_ +%= v1_; v1_ <<>= 17; v1_ ^= v2_; v2_ <<>= 32;

        v0_ ^= bytes;

        v0 := v0_;
        v1 := v1_;
        v2 := v2_;
        v3 := v3_;
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
          let x = Nat64.fromNat(Nat8.toNat(bytes[ix]));
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
          = (Nat64.fromNat(Nat8.toNat(bytes[ix    ])) <<  0)
          | (Nat64.fromNat(Nat8.toNat(bytes[ix + 1])) <<  8)
          | (Nat64.fromNat(Nat8.toNat(bytes[ix + 2])) << 16)
          | (Nat64.fromNat(Nat8.toNat(bytes[ix + 3])) << 24)
          | (Nat64.fromNat(Nat8.toNat(bytes[ix + 4])) << 32)
          | (Nat64.fromNat(Nat8.toNat(bytes[ix + 5])) << 40)
          | (Nat64.fromNat(Nat8.toNat(bytes[ix + 6])) << 48)
          | (Nat64.fromNat(Nat8.toNat(bytes[ix + 7])) << 56);

        v3_ ^= block;

        v0_ +%= v1_; v1_ <<>= 13; v1_ ^= v0_; v0_ <<>= 32;
        v2_ +%= v3_; v3_ <<>= 16; v3_ ^= v2_;
        v0_ +%= v3_; v3_ <<>= 21; v3_ ^= v0_;
        v2_ +%= v1_; v1_ <<>= 17; v1_ ^= v2_; v2_ <<>= 32;

        v0_ ^= block;

        ix += 8;
      };
      v0 := v0_;
      v1 := v1_;
      v2 := v2_;
      v3 := v3_;


      // We know the remaining bytes aren't enough to fill a full block,
      // so append them to tail
      while (ix < size_nat) {
        let x = Nat64.fromNat(Nat8.toNat(bytes[ix]));
        ix += 1;
        tail |= x << (8 * ntail);
        ntail += 1;
      };
    };

    // Literal copy of writeBytes
    public func writeBlob(bytes: Blob) {
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
          let x = Nat64.fromNat(Nat8.toNat(bytes[ix]));
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
          = (Nat64.fromNat(Nat8.toNat(bytes[ix    ])) <<  0)
          | (Nat64.fromNat(Nat8.toNat(bytes[ix + 1])) <<  8)
          | (Nat64.fromNat(Nat8.toNat(bytes[ix + 2])) << 16)
          | (Nat64.fromNat(Nat8.toNat(bytes[ix + 3])) << 24)
          | (Nat64.fromNat(Nat8.toNat(bytes[ix + 4])) << 32)
          | (Nat64.fromNat(Nat8.toNat(bytes[ix + 5])) << 40)
          | (Nat64.fromNat(Nat8.toNat(bytes[ix + 6])) << 48)
          | (Nat64.fromNat(Nat8.toNat(bytes[ix + 7])) << 56);

        v3_ ^= block;

        v0_ +%= v1_; v1_ <<>= 13; v1_ ^= v0_; v0_ <<>= 32;
        v2_ +%= v3_; v3_ <<>= 16; v3_ ^= v2_;
        v0_ +%= v3_; v3_ <<>= 21; v3_ ^= v0_;
        v2_ +%= v1_; v1_ <<>= 17; v1_ ^= v2_; v2_ <<>= 32;

        v0_ ^= block;

        ix += 8;
      };
      v0 := v0_;
      v1 := v1_;
      v2 := v2_;
      v3 := v3_;


      // We know the remaining bytes aren't enough to fill a full block,
      // so append them to tail
      while (ix < size_nat) {
        let x = Nat64.fromNat(Nat8.toNat(bytes[ix]));
        ix += 1;
        tail |= x << (8 * ntail);
        ntail += 1;
      };
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

    // Inlined everywhere
    // func compress() {
    //   var v0_ = v0;
    //   var v1_ = v1;
    //   var v2_ = v2;
    //   var v3_ = v3;
    //   v0_ +%= v1_; v1_ <<>= 13; v1_ ^= v0_; v0_ <<>= 32;
    //   v2_ +%= v3_; v3_ <<>= 16; v3_ ^= v2_;
    //   v0_ +%= v3_; v3_ <<>= 21; v3_ ^= v0_;
    //   v2_ +%= v1_; v1_ <<>= 17; v1_ ^= v2_; v2_ <<>= 32;
    //   v0 := v0_;
    //   v1 := v1_;
    //   v2 := v2_;
    //   v3 := v3_;
    // };
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

  public func hashBlob(seed : (Nat64, Nat64), bytes : Blob) : Nat64 {
    var v0 : Nat64 = 0x736f6d6570736575 ^ seed.0;
    var v1 : Nat64 = 0x646f72616e646f6d ^ seed.1;
    var v2 : Nat64 = 0x6c7967656e657261 ^ seed.0;
    var v3 : Nat64 = 0x7465646279746573 ^ seed.1;
    let length : Nat = bytes.size();
    var tail : Nat64 = 0;

    var ix : Nat = 0;

    // Write as many full blocks as we can
    while ((length - ix) : Nat >= 8) {
      let block : Nat64
        = (Nat64.fromNat(Nat8.toNat(bytes[ix    ])) <<  0)
        | (Nat64.fromNat(Nat8.toNat(bytes[ix + 1])) <<  8)
        | (Nat64.fromNat(Nat8.toNat(bytes[ix + 2])) << 16)
        | (Nat64.fromNat(Nat8.toNat(bytes[ix + 3])) << 24)
        | (Nat64.fromNat(Nat8.toNat(bytes[ix + 4])) << 32)
        | (Nat64.fromNat(Nat8.toNat(bytes[ix + 5])) << 40)
        | (Nat64.fromNat(Nat8.toNat(bytes[ix + 6])) << 48)
        | (Nat64.fromNat(Nat8.toNat(bytes[ix + 7])) << 56);

      v3 ^= block;

      v0 +%= v1; v1 <<>= 13; v1 ^= v0; v0 <<>= 32;
      v2 +%= v3; v3 <<>= 16; v3 ^= v2;
      v0 +%= v3; v3 <<>= 21; v3 ^= v0;
      v2 +%= v1; v1 <<>= 17; v1 ^= v2; v2 <<>= 32;

      v0 ^= block;

      ix += 8;
    };

    // We know the remaining bytes aren't enough to fill a full block,
    // so append them to tail
    var ntail : Nat64 = 0;
    while (ix < length) {
      let x = Nat64.fromNat(Nat8.toNat(bytes[ix]));
      ix += 1;
      tail |= x << (8 * ntail);
      ntail += 1;
    };

    let b : Nat64 = ((Nat64.fromNat(length) & 0xff) << 56) | tail;

    v3 ^= b;

    v0 +%= v1; v1 <<>= 13; v1 ^= v0; v0 <<>= 32;
    v2 +%= v3; v3 <<>= 16; v3 ^= v2;
    v0 +%= v3; v3 <<>= 21; v3 ^= v0;
    v2 +%= v1; v1 <<>= 17; v1 ^= v2; v2 <<>= 32;

    v0 ^= b;

    v2 ^= 0xff;

    // 3 Inlined compress rounds
    v0 +%= v1; v1 <<>= 13; v1 ^= v0; v0 <<>= 32;
    v2 +%= v3; v3 <<>= 16; v3 ^= v2;
    v0 +%= v3; v3 <<>= 21; v3 ^= v0;
    v2 +%= v1; v1 <<>= 17; v1 ^= v2; v2 <<>= 32;

    v0 +%= v1; v1 <<>= 13; v1 ^= v0; v0 <<>= 32;
    v2 +%= v3; v3 <<>= 16; v3 ^= v2;
    v0 +%= v3; v3 <<>= 21; v3 ^= v0;
    v2 +%= v1; v1 <<>= 17; v1 ^= v2; v2 <<>= 32;

    v0 +%= v1; v1 <<>= 13; v1 ^= v0; v0 <<>= 32;
    v2 +%= v3; v3 <<>= 16; v3 ^= v2;
    v0 +%= v3; v3 <<>= 21; v3 ^= v0;
    v2 +%= v1; v1 <<>= 17; v1 ^= v2; v2 <<>= 32;

    v0 ^ v1 ^ v2 ^ v3
  };

  public func hashText(seed : (Nat64, Nat64), text : Text) : Nat64 {
    hashBlob(seed, Text.encodeUtf8(text))
  };

  public func hashNat(seed : (Nat64, Nat64), nat : Nat) : Nat64 {
    var v0 : Nat64 = 0x736f6d6570736575 ^ seed.0;
    var v1 : Nat64 = 0x646f72616e646f6d ^ seed.1;
    var v2 : Nat64 = 0x6c7967656e657261 ^ seed.0;
    var v3 : Nat64 = 0x7465646279746573 ^ seed.1;

    var length : Nat64 = 0;
    var n : Nat = nat;


    while (n != 0) {
      length += 8;
      let block = Nat64.fromIntWrap(n);

      v3 ^= block;

      v0 +%= v1; v1 <<>= 13; v1 ^= v0; v0 <<>= 32;
      v2 +%= v3; v3 <<>= 16; v3 ^= v2;
      v0 +%= v3; v3 <<>= 21; v3 ^= v0;
      v2 +%= v1; v1 <<>= 17; v1 ^= v2; v2 <<>= 32;

      v0 ^= block;

      n := Nat.bitshiftRight(n, 64);
    };

    let b : Nat64 = (length & 0xff) << 56;

    v3 ^= b;

    v0 +%= v1; v1 <<>= 13; v1 ^= v0; v0 <<>= 32;
    v2 +%= v3; v3 <<>= 16; v3 ^= v2;
    v0 +%= v3; v3 <<>= 21; v3 ^= v0;
    v2 +%= v1; v1 <<>= 17; v1 ^= v2; v2 <<>= 32;

    v0 ^= b;

    v2 ^= 0xff;

    // 3 Inlined compress rounds
    v0 +%= v1; v1 <<>= 13; v1 ^= v0; v0 <<>= 32;
    v2 +%= v3; v3 <<>= 16; v3 ^= v2;
    v0 +%= v3; v3 <<>= 21; v3 ^= v0;
    v2 +%= v1; v1 <<>= 17; v1 ^= v2; v2 <<>= 32;

    v0 +%= v1; v1 <<>= 13; v1 ^= v0; v0 <<>= 32;
    v2 +%= v3; v3 <<>= 16; v3 ^= v2;
    v0 +%= v3; v3 <<>= 21; v3 ^= v0;
    v2 +%= v1; v1 <<>= 17; v1 ^= v2; v2 <<>= 32;

    v0 +%= v1; v1 <<>= 13; v1 ^= v0; v0 <<>= 32;
    v2 +%= v3; v3 <<>= 16; v3 ^= v2;
    v0 +%= v3; v3 <<>= 21; v3 ^= v0;
    v2 +%= v1; v1 <<>= 17; v1 ^= v2; v2 <<>= 32;

    v0 ^ v1 ^ v2 ^ v3
  };

  public func hashInt(seed : (Nat64, Nat64), int : Int) : Nat64  {
    // Maps all positive integers to 2, 4, 6, ... and all negative ones to 1, 3, 5, ...
    var x : Nat = Int.abs(int) * 2;
    if (int < 0) {
      x -= 1;
    };
    hashNat(seed, x);
  };

}
