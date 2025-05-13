use std::io::Write;
use std::hash::Hasher;
use std::fs;
use siphasher::sip::SipHasher13;

fn mk_u64_test_vector(mut w: impl Write, k1 : u64, k2 : u64, seed : u64, rounds : u32) {
    writeln!(w, r#"import Nat "mo:base/Nat";
import Nat64 "mo:base/Nat64";
import Debug "mo:base/Debug";
import Sip "../src/Sip13";

module {{"#
    ).unwrap();
    writeln!(w, "  let k1 : Nat64 = 0x{k1:X};").unwrap();
    writeln!(w, "  let k2 : Nat64 = 0x{k2:X};").unwrap();
    writeln!(w, "  let vec : [Nat64] = [").unwrap();

    let mut current = seed;
    writeln!(w, "    0x{seed:X},").unwrap();
    for _ in 0..rounds {
        let mut hasher = SipHasher13::new_with_keys(k1, k2);
        hasher.write_u64(current);
        let next = hasher.finish();
        writeln!(w, "    0x{next:X},").unwrap();
        current = next;
    }
    writeln!(w, "  ];").unwrap();
    writeln!(w, r#"
  public func test() {{
    var i : Nat = 1;
    var current = vec[0];
    while (i < vec.size()) {{
      let hasher = Sip.SipHasher13(k1, k2);
      hasher.writeNat64(current);
      let next = hasher.finish();
      if (next != vec[i]) {{
        Debug.print("Failed at " # Nat.toText(i) # ": " # Nat64.toText(next) # " != " # Nat64.toText(vec[i]));
        assert false;
      }};
      current := next;
      i += 1;
    }};
  }};"#).unwrap();
    writeln!(w, "}};").unwrap();
}

fn mk_text_test_vector(mut w: impl Write, k1 : u64, k2 : u64, rounds : u32) {
    writeln!(w, r#"import Nat "mo:base/Nat";
import Nat64 "mo:base/Nat64";
import Debug "mo:base/Debug";
import Sip "../src/Sip13";

module {{"#
    ).unwrap();
    writeln!(w, "  let k1 : Nat64 = 0x{k1:X};").unwrap();
    writeln!(w, "  let k2 : Nat64 = 0x{k2:X};").unwrap();
    writeln!(w, "  let vec : [(Text, Nat64)] = [").unwrap();

    let dict = fs::read_to_string("dictionary.txt").unwrap();
    for line in dict.lines().take(rounds as usize) {
        let mut hasher = SipHasher13::new_with_keys(k1, k2);
        hasher.write(line.as_bytes());
        let out = hasher.finish();
        writeln!(w, "    (\"{line}\", 0x{out:X}),").unwrap();
    }

    writeln!(w, "  ];").unwrap();
    writeln!(w, r#"

  public func test() {{
    var i : Nat = 0;
    while (i < vec.size()) {{
      let (text, hash) = vec[i];
      let hasher = Sip.SipHasher13(k1, k2);
      hasher.writeText(text);
      let next = hasher.finish();
      if (next != hash) {{
        Debug.print("Failed at " # Nat.toText(i) # ": \"" # text # "\" /=> " # Nat64.toText(hash));
        assert false;
      }};
      i += 1;
    }};
  }};"#).unwrap();
    writeln!(w, "}};").unwrap();
}

fn main() {
    let mut nat64_test = fs::File::create("../test/Nat64.mo").unwrap();
    mk_u64_test_vector(&mut nat64_test, 2389294459135787592, 17865012505422766641,9256366987270737912, 10_000);

    let mut text_test = fs::File::create("../test/Text.mo").unwrap();
    mk_text_test_vector(&mut text_test, 9640917070887187917, 15189360200716670480, 10_000);
}
