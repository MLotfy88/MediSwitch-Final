
import json
import re
from html.parser import HTMLParser

class TableToMarkdown(HTMLParser):
    def __init__(self):
        super().__init__()
        self.output = []
        self.in_td = False
        self.in_th = False
        self.current_row = []
        self.rows = []
        self.capture_text = False

    def handle_starttag(self, tag, attrs):
        if tag == 'tr':
            self.current_row = []
        elif tag in ('td', 'th'):
            self.in_td = True
            self.capture_text = ""

    def handle_endtag(self, tag):
        if tag == 'tr':
            self.rows.append(self.current_row)
        elif tag in ('td', 'th'):
            self.in_td = False
            # Clean up text: replace newlines with space, remove extra whitespace
            clean_text = ' '.join(self.capture_text.split())
            self.current_row.append(clean_text)

    def handle_data(self, data):
        if self.in_td:
            self.capture_text += data

    def get_markdown(self):
        md = []
        if not self.rows:
            return ""
        
        # Determine number of columns
        num_cols = max(len(row) for row in self.rows) if self.rows else 0
        if num_cols == 0: return ""

        # Header (Use first row as header if it looks like one, or empty)
        # For simplicity, we'll just treat the first row as header if it's the only logic we have, 
        # or just print all as rows. Let's print all as rows but add a dummy header if needed.
        # Actually standard markdown table needs a header.
        
        header = self.rows[0]
        # Pad header if needed
        while len(header) < num_cols: header.append("")
        
        md.append("| " + " | ".join(header) + " |")
        md.append("| " + " | ".join(["---"] * num_cols) + " |")
        
        for row in self.rows[1:]:
            # Pad row
            while len(row) < num_cols: row.append("")
            md.append("| " + " | ".join(row) + " |")
            
        return "\n".join(md)

def render_mockup():
    with open('openfda_sample.json', 'r') as f:
        data = json.load(f)
    
    product = data['results'][0]
    tables_html = product.get('dosage_and_administration_table', [])
    
    mockup_lines = []
    mockup_lines.append("# 📱 معاينة التطبيق: Dormicum (Midazolam)")
    mockup_lines.append("\nهذا هو ما سيراه الطبيب في تبويب **الجرعة والاستخدام (Dosage & Admin)**.\n")
    mockup_lines.append("> 💡 **ملاحظة:** هذه البيانات مستجليبة مباشرة من المصدر الرسمي (OpenFDA) وتم تنسيقها كجداول.\n")

    for i, html in enumerate(tables_html):
        parser = TableToMarkdown()
        parser.feed(html)
        markdown_table = parser.get_markdown()
        
        if markdown_table:
            mockup_lines.append(f"### 📋 جدول إرشادات الجرعة ({i+1})")
            mockup_lines.append(markdown_table)
            mockup_lines.append("\n---\n")
    
    # Also add the Calculator simulation at the bottom
    mockup_lines.append("\n# 🧮 المحرك الخفي (Mini Calculator)")
    mockup_lines.append("بينما يقرأ الطبيب الجداول أعلاه، تقوم الحاسبة في الخلفية باستخدام البيانات التالية:")
    mockup_lines.append("```json")
    mockup_lines.append(json.dumps([
        {
          "Population": "Adults (<60)",
          "Dose": "0.07-0.08 mg/kg",
          "Max": "5 mg"
        },
        {
          "Population": "Pediatrics (6-12)",
          "Dose": "0.025-0.05 mg/kg",
          "Max": "10 mg"
        }
    ], indent=2))
    mockup_lines.append("```")

    with open('Dormicum_Visual_Mockup.md', 'w') as f:
        f.write("\n".join(mockup_lines))
    print("Mockup generated: Dormicum_Visual_Mockup.md")

if __name__ == "__main__":
    render_mockup()
