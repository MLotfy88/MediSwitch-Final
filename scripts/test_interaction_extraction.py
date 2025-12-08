#!/usr/bin/env python3
"""
Test Drug Interaction Extraction Quality
Validates the improved find_interacting_drug function
"""

import sys
import os
sys.path.insert(0, os.path.join(os.path.dirname(__file__), 'interactions'))

from download_and_extract_openfda import find_interacting_drug, load_known_ingredients

# Test cases with known interactions
TEST_CASES = [
    {
        "text": "Concomitant use of warfarin and aspirin may increase bleeding risk",
        "current_drug": "warfarin",
        "expected": "aspirin",
        "description": "Simple 'with' pattern"
    },
    {
        "text": "When co-administered with metformin, dose adjustment may be necessary",
        "current_drug": "insulin",
        "expected": "metformin",
        "description": "Co-administered pattern"
    },
    {
        "text": "Patients taking amoxicillin should avoid alcohol consumption",
        "current_drug": "amoxicillin",
        "expected": "alcohol",
        "description": "Drug class detection"
    },
    {
        "text": "The combination of simvastatin with grapefruit juice is contraindicated",
        "current_drug": "simvastatin",
        "expected": "grapefruit",  # grapefruit juice -> grapefruit
        "description": "Food interaction"
    },
    {
        "text": "Concurrent use of ACE inhibitors may result in hyperkalemia",
        "current_drug": "lisinopril",
        "expected": "ace inhibitors",
        "description": "Drug class"
    },
    {
        "text": "Interaction with NSAIDs may increase risk of gastrointestinal bleeding",
        "current_drug": "warfarin",
        "expected": "nsaids",
        "description": "Abbreviation class"
    },
    {
        "text": "The use of clarithromycin with digoxin can increase digoxin levels",
        "current_drug": "digoxin",
        "expected": "clarithromycin",  
        "description": "Reverse order"
    },
]

def test_extraction_quality():
    """Test the find_interacting_drug function"""
    print("="*70)
    print("🧪 اختبار جودة استخراج المادة الفعالة الثانية")
    print("="*70)
    
    # Load known ingredients
    print("\n📚 تحميل قائمة المواد الفعالة...")
    ingredients_file = 'assets/data/medicine_ingredients.json'
    if not os.path.exists(ingredients_file):
        print(f"⚠️ تحذير: لم يتم العثور على {ingredients_file}")
        print("   سيتم الاختبار بدون قائمة المواد الفعالة")
        known_ingredients = []
    else:
        known_ingredients = load_known_ingredients(ingredients_file)
        print(f"✅ تم تحميل {len(known_ingredients):,} مادة فعالة")
    
    # Run tests
    passed = 0
    failed = 0
    
    print("\n" + "="*70)
    print("اختبار الحالات المعروفة:")
    print("="*70 + "\n")
    
    for i, test in enumerate(TEST_CASES, 1):
        result = find_interacting_drug(
            test["text"], 
            test["current_drug"], 
            known_ingredients
        )
        
        success = test["expected"] in result.lower() or result.lower() in test["expected"]
        
        status = "✅" if success else "❌"
        print(f"{status} Test {i}: {test['description']}")
        print(f"   النص: {test['text'][:80]}...")
        print(f"   المتوقع: {test['expected']}")
        print(f"   النتيجة: {result}")
        
        if success:
            passed += 1
        else:
            failed += 1
        print()
    
    # Summary
    print("="*70)
    print("📊 ملخص النتائج")
    print("="*70)
    total = passed + failed
    success_rate = (passed / total * 100) if total > 0 else 0
    
    print(f"✅ نجح: {passed}/{total}")
    print(f"❌ فشل: {failed}/{total}")
    print(f"📈 معدل النجاح: {success_rate:.1f}%")
    
    if success_rate >= 70:
        print("\n🎉 ممتاز! الدالة تعمل بشكل جيد")
        return 0
    elif success_rate >= 50:
        print("\n⚠️ جيد لكن يحتاج تحسين")
        return 0
    else:
        print("\n❌ ضعيف - يحتاج مراجعة")
        return 1

if __name__ == '__main__':
    sys.exit(test_extraction_quality())
