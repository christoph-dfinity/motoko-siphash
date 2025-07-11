import Blob "mo:core/Blob";
import Int "mo:core/Int";
import Int16 "mo:core/Int16";
import Int32 "mo:core/Int32";
import Int64 "mo:core/Int64";
import Int8 "mo:core/Int8";
import Nat "mo:core/Nat";
import Nat16 "mo:core/Nat16";
import Nat32 "mo:core/Nat32";
import Nat64 "mo:core/Nat64";
import Nat8 "mo:core/Nat8";
import Text "mo:core/Text";

module {
  public type Hasher = {
    writeNat8 : Nat8 -> ();
    writeNat16 : Nat16 -> ();
    writeNat32 : Nat32 -> ();
    writeNat64 : Nat64 -> ();
    writeBytes : [Nat8] -> ();
    writeBlob : Blob -> ();
    reset : () -> ();
    finish : () -> Nat64;
  };

  public func nat(h : Hasher, nat : Nat) {
    var count : Nat64 = 1;
    var n = nat;
    h.writeNat64(Nat64.fromIntWrap(n));
    n := Nat.bitshiftRight(n, 64);

    while (n != 0) {
      count += 1;
      h.writeNat64(Nat64.fromIntWrap(n));
      n := Nat.bitshiftRight(n, 64);
    };
    // Prefix-free
    h.writeNat64(count);
  };

  public func int(h : Hasher, int : Int) {
    // Maps all positive integers to 2, 4, 6, ... and all negative ones to 1, 3, 5, ...
    var x : Nat = Int.abs(int) * 2;
    if (int < 0) {
      x -= 1;
    };
    nat(h, x);
  };

  public func int8(h : Hasher, x : Int8) = h.writeNat8(Int8.toNat8(x));
  public func int16(h : Hasher, x : Int16) = h.writeNat16(Int16.toNat16(x));
  public func int32(h : Hasher, x : Int32) = h.writeNat32(Int32.toNat32(x));
  public func int64(h : Hasher, x : Int64) = h.writeNat64(Int64.toNat64(x));

  public func text(h : Hasher, text : Text) {
    h.writeBlob(Text.encodeUtf8(text));
    // Prefix-free. Makes it so `("a", "b")` doesn't produce the same hash as `("ab", "")`
    h.writeNat8(0xFF);
  };

  public func array<A>(h : Hasher, hashA : (Hasher, A) -> (), arr : [A]) {
    let size = arr.size();
    // Prefix-free. Makes it so `([], [1, 2])` doesn't produce the same hash as `([1], [2])`
    h.writeNat64(Nat64.fromNat(size));
    var i = 0;
    while (i < size) {
      hashA(h, arr[i]);
      i += 1;
    }
  };

  // Verbatim copy of array
  public func arrayVar<A>(h : Hasher, hashA : (Hasher, A) -> (), arr : [var A]) {
    let size = arr.size();
    // Prefix-free. Makes it so `([], [1, 2])` doesn't produce the same hash as `([1], [2])`
    h.writeNat64(Nat64.fromNat(size));
    var i = 0;
    while (i < size) {
      hashA(h, arr[i]);
      i += 1;
    }
  };
};
