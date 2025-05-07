import M "mo:matchers/Matchers";
import S "mo:matchers/Suite";
import T "mo:matchers/Testable";
import Sip "../src/Sip";

let tup3T : T.Testable<(Nat64, Nat64, Nat64)> = {
  display = func t = debug_show t;
  equals = func (t1, t2) = t1 == t2;
};

func tup3(x : Nat64, y : Nat64, z : Nat64): T.TestableItem<(Nat64, Nat64, Nat64)> =
  { tup3T with item = (x, y, z)  };

func test_cases(hasher: Sip.SipHasher13): (Nat64, Nat64, Nat64) {
    hasher.reset();
    let out1 = hasher.finish();

    hasher.reset();
    hasher.write_nat64(out1);
    let out2 = hasher.finish();

    hasher.reset();
    for (byte in ("Motoko is beautiful" : Blob).values()) {
      hasher.write_nat8(byte);
    };
    let out3 = hasher.finish();
    (out1, out2, out3)
};

let suite = S.suite("sip13", [
  S.test("unkeyed",
    test_cases(Sip.SipHasher13(0, 0)),
    M.equals(tup3(
      15130871412783076140,
      3836723192557835904,
      5686842280097475325,
    ))
  ),
  S.test("keyed",
    test_cases(Sip.SipHasher13(1, 2)),
    M.equals(tup3(
      7760257379124798368,
      18435053342948331089,
      15173025143249511568,
    ))
  ),
]);

S.run(suite);
