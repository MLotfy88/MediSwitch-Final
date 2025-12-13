import sys
import os

# Add scripts dir to path to import process_datalake
sys.path.append(os.path.join(os.getcwd(), 'scripts'))

from process_datalake import normalize_active_ingredient

def test_normalization():
    print("🧪 Testing Aggressive Normalization...")
    
    test_cases = [
        # (Input, Expected_Stripped, Expected_Exact)
        ("Paracetamol", "acetaminophen", "acetaminophen"),
        ("Diclofenac Sodium", "diclofenac", "diclofenac sodium"), # Exact keeps salt
        ("Metformin Hydrochloride", "metformin", "metformin"), # Exact keeps salt? No, hydrochloride is normalized? check logic
        # Wait, if I strip HCL, it's metformin. If I keep it, it's metformin hydrochloride.
        # But wait, does 'metformin' map to 'metformin hydrochloride' in my code?
        # My code just tokenizes.
        ("Amoxycillin + Clavulanic Acid", "acid amoxicillin clavulanic", "acid amoxicillin clavulanic"),
        ("Adrenaline", "epinephrine", "epinephrine"), # Synonym works in both
        ("Bendrofluazide", "bendroflumethiazide", "bendroflumethiazide"),
        ("Cefalexin", "cephalexin", "cephalexin"),
    ]
    
    passed = 0
    total = 0
    for input_str, exp_stripped, exp_exact in test_cases:
        # Test Stripped
        res_stripped = normalize_active_ingredient(input_str, strip_salts=True)
        if res_stripped == exp_stripped:
            print(f"✅ [Stripped] '{input_str}' -> '{res_stripped}'")
            passed += 1
        else:
            print(f"❌ [Stripped] '{input_str}' -> '{res_stripped}' (Expected: '{exp_stripped}')")
        total += 1
            
        # Test Exact
        res_exact = normalize_active_ingredient(input_str, strip_salts=False)
        # Note: My code regex replaces HCL/Sodium ONLY if strip_salts=True.
        # So 'Diclofenac Sodium' -> 'diclofenac sodium' (sorted)
        if res_exact == exp_exact:
             print(f"✅ [Exact]    '{input_str}' -> '{res_exact}'")
             passed += 1
        else:
             print(f"❌ [Exact]    '{input_str}' -> '{res_exact}' (Expected: '{exp_exact}')")
        total += 1
            
    print(f"\nScore: {passed}/{total}")

if __name__ == "__main__":
    test_normalization()
