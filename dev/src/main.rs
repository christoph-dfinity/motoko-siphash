use std::hash::DefaultHasher;
use std::hash::Hasher;
use siphasher::sip::SipHasher13;

fn test_cases(hasher: impl Hasher + Clone) {
    let hasher1 = hasher.clone();
    let out = hasher1.finish();
    println!("{out}");

    let mut hasher2 = hasher.clone();
    hasher2.write_u64(out);
    let out = hasher2.finish();
    println!("{out}");

    let mut hasher3 = hasher.clone();
    for byte in "Motoko is beautiful".bytes() {
        hasher3.write_u8(byte);
    }
    let out = hasher3.finish();
    println!("{out}");
}

fn main() {
    test_cases(DefaultHasher::default());
    test_cases(SipHasher13::new_with_keys(1, 2));
}
