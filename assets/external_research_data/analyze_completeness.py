#!/usr/bin/env python3
"""
Database Completeness Analyzer
===============================
تحليل شامل لقاعدة بيانات DDInter لاكتشاف البيانات الناقصة
"""

import sqlite3
import json
from datetime import datetime

DB_PATH = 'ddinter_complete.db'

def analyze_table_completeness(conn, table_name):
    """تحليل اكتمال البيانات في جدول واحد"""
    cursor = conn.cursor()
    
    # الحصول على معلومات الأعمدة
    cursor.execute(f"PRAGMA table_info({table_name})")
    columns = cursor.fetchall()
    
    # الحصول على عدد الصفوف
    cursor.execute(f"SELECT COUNT(*) FROM {table_name}")
    total_rows = cursor.fetchone()[0]
    
    if total_rows == 0:
        return {
            'table_name': table_name,
            'total_rows': 0,
            'columns': [],
            'message': 'Table is empty'
        }
    
    results = []
    
    for col in columns:
        col_name = col[1]
        col_type = col[2]
        
        # حساب القيم الفارغة (NULL أو '')
        cursor.execute(f"""
            SELECT COUNT(*) FROM {table_name} 
            WHERE {col_name} IS NULL OR {col_name} = ''
        """)
        null_count = cursor.fetchone()[0]
        
        # حساب القيم غير الفارغة
        filled_count = total_rows - null_count
        
        # النسب المئوية
        null_percentage = (null_count / total_rows) * 100
        filled_percentage = (filled_count / total_rows) * 100
        
        results.append({
            'column_name': col_name,
            'column_type': col_type,
            'total_rows': total_rows,
            'filled': filled_count,
            'null_or_empty': null_count,
            'filled_percentage': round(filled_percentage, 2),
            'null_percentage': round(null_percentage, 2)
        })
    
    return {
        'table_name': table_name,
        'total_rows': total_rows,
        'columns': results
    }

def generate_report(analysis_results):
    """إنشاء تقرير HTML منسق"""
    
    timestamp = datetime.now().strftime('%Y-%m-%d %H:%M:%S')
    
    html = f"""
    <!DOCTYPE html>
    <html dir="rtl" lang="ar">
    <head>
        <meta charset="UTF-8">
        <title>تقرير اكتمال قاعدة البيانات</title>
        <style>
            body {{
                font-family: Arial, sans-serif;
                margin: 20px;
                direction: rtl;
            }}
            h1 {{
                color: #2c3e50;
                border-bottom: 3px solid #3498db;
                padding-bottom: 10px;
            }}
            h2 {{
                color: #34495e;
                margin-top: 30px;
            }}
            table {{
                border-collapse: collapse;
                width: 100%;
                margin: 20px 0;
                box-shadow: 0 2px 5px rgba(0,0,0,0.1);
            }}
            th {{
                background-color: #3498db;
                color: white;
                padding: 12px;
                text-align: right;
            }}
            td {{
                padding: 10px;
                border: 1px solid #ddd;
                text-align: right;
            }}
            tr:nth-child(even) {{
                background-color: #f9f9f9;
            }}
            .high-empty {{
                background-color: #e74c3c;
                color: white;
                font-weight: bold;
            }}
            .medium-empty {{
                background-color: #f39c12;
                color: white;
            }}
            .low-empty {{
                background-color: #2ecc71;
                color: white;
            }}
            .full {{
                background-color: #27ae60;
                color: white;
                font-weight: bold;
            }}
            .summary {{
                background-color: #ecf0f1;
                padding: 15px;
                border-radius: 5px;
                margin: 20px 0;
            }}
            .stats {{
                display: inline-block;
                margin: 10px 20px;
                font-size: 18px;
            }}
        </style>
    </head>
    <body>
        <h1>📊 تقرير اكتمال قاعدة بيانات DDInter</h1>
        <div class="summary">
            <p><strong>📅 تاريخ التحليل:</strong> {timestamp}</p>
            <p><strong>🗄️ قاعدة البيانات:</strong> {DB_PATH}</p>
        </div>
    """
    
    for table_data in analysis_results:
        table_name = table_data['table_name']
        total_rows = table_data['total_rows']
        
        html += f"""
        <h2>📋 جدول: {table_name}</h2>
        <div class="summary">
            <span class="stats">📊 عدد الصفوف: <strong>{total_rows:,}</strong></span>
        </div>
        """
        
        if total_rows == 0:
            html += "<p>⚠️ الجدول فارغ تماماً</p>"
            continue
        
        html += """
        <table>
            <thead>
                <tr>
                    <th>اسم العمود</th>
                    <th>النوع</th>
                    <th>مملوء</th>
                    <th>فارغ</th>
                    <th>نسبة الامتلاء</th>
                    <th>الحالة</th>
                </tr>
            </thead>
            <tbody>
        """
        
        for col in table_data['columns']:
            # تحديد اللون بناءً على نسبة الفراغ
            if col['null_percentage'] == 0:
                status_class = 'full'
                status_text = '✅ ممتاز'
            elif col['null_percentage'] < 25:
                status_class = 'low-empty'
                status_text = '✓ جيد'
            elif col['null_percentage'] < 75:
                status_class = 'medium-empty'
                status_text = '⚠️ متوسط'
            else:
                status_class = 'high-empty'
                status_text = '❌ ضعيف'
            
            html += f"""
            <tr>
                <td><strong>{col['column_name']}</strong></td>
                <td>{col['column_type']}</td>
                <td>{col['filled']:,} ({col['filled_percentage']}%)</td>
                <td>{col['null_or_empty']:,} ({col['null_percentage']}%)</td>
                <td>
                    <div style="background: linear-gradient(to right, #2ecc71 {col['filled_percentage']}%, #e74c3c {col['filled_percentage']}%); 
                                height: 20px; border-radius: 10px; text-align: center; color: white; font-weight: bold;">
                        {col['filled_percentage']}%
                    </div>
                </td>
                <td class="{status_class}">{status_text}</td>
            </tr>
            """
        
        html += """
            </tbody>
        </table>
        """
    
    html += """
    </body>
    </html>
    """
    
    return html

def main():
    print("="*70)
    print("📊 DDInter Database Completeness Analyzer")
    print("="*70)
    
    conn = sqlite3.connect(DB_PATH)
    cursor = conn.cursor()
    
    # الحصول على جميع الجداول
    cursor.execute("SELECT name FROM sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%'")
    tables = [row[0] for row in cursor.fetchall()]
    
    print(f"\n🔍 Found {len(tables)} tables to analyze...\n")
    
    all_results = []
    
    for table_name in tables:
        print(f"Analyzing: {table_name}...", end=" ")
        result = analyze_table_completeness(conn, table_name)
        all_results.append(result)
        print(f"✓ ({result['total_rows']:,} rows)")
    
    conn.close()
    
    # إنشاء التقرير
    print("\n📄 Generating report...")
    html_report = generate_report(all_results)
    
    # حفظ التقرير
    report_path = 'database_completeness_report.html'
    with open(report_path, 'w', encoding='utf-8') as f:
        f.write(html_report)
    
    # حفظ JSON للتحليل البرمجي
    json_path = 'database_completeness_report.json'
    with open(json_path, 'w', encoding='utf-8') as f:
        json.dump(all_results, f, ensure_ascii=False, indent=2)
    
    print(f"\n✅ Reports generated:")
    print(f"   📊 HTML: {report_path}")
    print(f"   📝 JSON: {json_path}")
    print("="*70)

if __name__ == "__main__":
    main()
