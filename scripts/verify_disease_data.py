import sqlite3
import json

DB_PATH = 'ddinter_data/ddinter_complete.db'

def verify_disease_data():
    print("🕵️ التحقق من تفاعلات الأمراض (Disease Interactions)...\n")
    conn = sqlite3.connect(DB_PATH)
    cursor = conn.cursor()

    # Check Disease Interactions
    cursor.execute("SELECT COUNT(*) FROM drug_disease_interactions")
    disease_count = cursor.fetchone()[0]
    
    print(f"📊 إجمالي سجلات تفاعلات الأمراض: {disease_count:,}")
    
    if disease_count > 0:
        cursor.execute("""
            SELECT d.drug_name, ddi.disease_name, ddi.interaction_text 
            FROM drug_disease_interactions ddi
            JOIN drugs d ON ddi.drug_id = d.ddinter_id
            LIMIT 5
        """)
        rows = cursor.fetchall()
        print("\n📝 أمثلة على البيانات:")
        for r in rows:
            # Truncate long text
            text = r[2][:100] + "..." if len(r[2]) > 100 else r[2]
            print(f"   💊 {r[0]} + 🦠 {r[1]}")
            print(f"      ⚠️  {text}\n")
            
    conn.close()

if __name__ == "__main__":
    verify_disease_data()
