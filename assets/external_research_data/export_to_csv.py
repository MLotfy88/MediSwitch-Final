#!/usr/bin/env python3
"""
Database to CSV Exporter
========================
تحويل قاعدة بيانات DDInter إلى ملفات CSV منفصلة
"""

import sqlite3
import csv
import os
from datetime import datetime

DB_PATH = 'ddinter_complete.db'
OUTPUT_DIR = 'csv_exports'

def export_table_to_csv(db_path, table_name, output_file):
    """تصدير جدول واحد إلى CSV"""
    conn = sqlite3.connect(db_path)
    conn.row_factory = sqlite3.Row
    cursor = conn.cursor()
    
    # جلب جميع البيانات
    cursor.execute(f"SELECT * FROM {table_name}")
    rows = cursor.fetchall()
    
    if not rows:
        print(f"⚠️  Table '{table_name}' is empty, skipping...")
        conn.close()
        return 0
    
    # الحصول على أسماء الأعمدة
    column_names = rows[0].keys()
    
    # كتابة CSV
    with open(output_file, 'w', encoding='utf-8', newline='') as f:
        writer = csv.DictWriter(f, fieldnames=column_names)
        writer.writeheader()
        
        for row in rows:
            writer.writerow(dict(row))
    
    conn.close()
    print(f"✅ Exported {len(rows):,} rows from '{table_name}' to {output_file}")
    return len(rows)

def main():
    print("="*70)
    print("📊 DDInter Database → CSV Exporter")
    print("="*70)
    
    if not os.path.exists(DB_PATH):
        print(f"❌ Database not found: {DB_PATH}")
        return
    
    # إنشاء مجلد الإخراج
    os.makedirs(OUTPUT_DIR, exist_ok=True)
    
    # قائمة الجداول للتصدير
    tables = {
        'drugs': 'drugs.csv',
        'drug_drug_interactions': 'drug_drug_interactions.csv',
        'drug_disease_interactions': 'drug_disease_interactions.csv',
        'drug_food_interactions': 'drug_food_interactions.csv',
        'compound_preparations': 'compound_preparations.csv'
    }
    
    total_rows = 0
    timestamp = datetime.now().strftime('%Y%m%d_%H%M%S')
    
    print(f"\n📁 Exporting to: {OUTPUT_DIR}/\n")
    
    for table_name, csv_filename in tables.items():
        output_path = os.path.join(OUTPUT_DIR, csv_filename)
        rows_count = export_table_to_csv(DB_PATH, table_name, output_path)
        total_rows += rows_count
    
    print("\n" + "="*70)
    print("🎉 Export Complete!")
    print("="*70)
    print(f"📊 Total rows exported: {total_rows:,}")
    print(f"📁 Files location: {OUTPUT_DIR}/")
    print(f"📅 Timestamp: {timestamp}")
    
    # عرض أحجام الملفات
    print("\n📦 File sizes:")
    for csv_file in os.listdir(OUTPUT_DIR):
        if csv_file.endswith('.csv'):
            file_path = os.path.join(OUTPUT_DIR, csv_file)
            size_mb = os.path.getsize(file_path) / (1024 * 1024)
            print(f"   {csv_file}: {size_mb:.2f} MB")
    
    print("="*70)

if __name__ == "__main__":
    main()
