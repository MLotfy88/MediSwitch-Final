
import json
import re
from html.parser import HTMLParser

class TableToMobileCards(HTMLParser):
    def __init__(self):
        super().__init__()
        self.rows = []
        self.current_row = []
        self.in_td = False
        self.in_th = False
        self.capture_text = ""
        self.headers = []
        self.is_header_row = True

    def handle_starttag(self, tag, attrs):
        if tag == 'tr':
            self.current_row = []
        elif tag in ('td', 'th'):
            self.in_td = True
            self.capture_text = ""

    def handle_endtag(self, tag):
        if tag == 'tr':
            if self.is_header_row:
                self.headers = self.current_row
                self.is_header_row = False
            else:
                self.rows.append(self.current_row)
            self.current_row = []
        elif tag in ('td', 'th'):
            self.in_td = False
            clean_text = ' '.join(self.capture_text.split())
            self.current_row.append(clean_text)

    def handle_data(self, data):
        if self.in_td:
            self.capture_text += data

    def get_mobile_cards(self):
        cards = []
        if not self.rows:
            return ""

        # ---------------------------------------------------------
        # SMART HEADER DETECTION LOGIC
        # ---------------------------------------------------------
        # Problem: Table 1 has header in Row 1. Table 2 has headers in Row 3.
        # Heuristic: The header row is usually the first row that has the same number of columns as the data rows,
        # OR it's the row with the most non-empty strings in the top 5 rows.
        
        # 1. Identify max columns in the table
        max_cols = max(len(r) for r in self.rows) if self.rows else 0
        
        # 2. Scan top 5 rows to find the "Best Header Candidate"
        # We prefer a row that has 'max_cols' items and meaningful text.
        header_row_index = -1
        candidate_headers = []

        for i, row in enumerate(self.rows[:5]):
            # If this row matches max_cols, it's a strong candidate
            if len(row) == max_cols:
                # Check quality: are cells distinct? (Avoids "Description... Description..." placeholders)
                non_empty = [c for c in row if c.strip()]
                if len(non_empty) > len(candidate_headers):
                    candidate_headers = row
                    header_row_index = i
        
        # 3. Fallback: If no good header found, maybe it's a Key-Value table (2 cols).
        # In that case, we can name them manually or stick to Info.
        if not candidate_headers:
            candidate_headers = [f"Column {i+1}" for i in range(max_cols)]
            best_data_start_index = 0
        else:
            best_data_start_index = header_row_index + 1

        # 4. Special Case Override for Known Patterns (Adaptive Parsing)
        # If we see specific keywords, we can impose better headers.
        header_str = " ".join(candidate_headers).lower()
        if "adult dose" in header_str and max_cols == 2:
            candidate_headers = ["Indication / Route", "Dosage Instruction"]
        elif "pediatric" in header_str and max_cols == 2:
            candidate_headers = ["Population / Indication", "Dosage Instruction"]

        self.headers = candidate_headers

        # ---------------------------------------------------------
        # GENERATE CARDS
        # ---------------------------------------------------------
        # Skip the header rows (rows before data start)
        data_rows = self.rows[best_data_start_index:]
        
        for row in data_rows:
            # Skip empty rows or sub-headers (rows that are just titles)
            if len([c for c in row if c.strip()]) < 2: 
                continue

            card_md = "> 📱 **Mobile Card**\n"
            
            # Key determination: The first cell is usually the "Title" of the card
            # But sometimes the first cell is empty (in nested tables).
            
            for i, cell in enumerate(row):
                if i >= len(self.headers): break # Safety
                
                header_label = self.headers[i]
                
                # Clean up content
                content = cell.strip() if cell else "-"
                if content == "-": continue # Skip empty fields in card to save space

                # Visual Logic: 
                # If it's the first column, make it the Card Title
                if i == 0:
                    card_md += f"> ### {content}\n"
                else:
                    card_md += f"> * **{header_label}:** {content}\n"
            
            cards.append(card_md)
        
        return "\n\n".join(cards)

def render_mobile_view():
    with open('openfda_sample.json', 'r') as f:
        data = json.load(f)
    
    product = data['results'][0]
    tables_html = product.get('dosage_and_administration_table', [])
    
    output_lines = []
    output_lines.append("# 📱 معاينة الموبايل: Dormicum (Adaptive UI)")
    output_lines.append("\nإجابة على سؤالك: **نعم، نملك التحكم الكامل.**")
    output_lines.append("بما أن البيانات تأتي كـ HTML مهيكل، يمكننا كسر \"قالب الجدول\" وتحويله إلى **بطاقات (Cards)** أو **قوائم (Lists)** تناسب شاشة الموبايل الطولية.\n")
    
    output_lines.append("## مقارنة التجربة (User Experience)")
    output_lines.append("بدلاً من إجبار الطبيب على التمرير يميناً ويساراً (Scroll Horizontal) في جدول، سنعرض له البيانات هكذا:\n")

    for i, html in enumerate(tables_html):
        parser = TableToMobileCards()
        parser.feed(html)
        mobile_cards = parser.get_mobile_cards()
        
        if mobile_cards:
            output_lines.append(f"### 🔽 قسم الجرعات رقم {i+1} (Card View)")
            output_lines.append(mobile_cards)
            output_lines.append("\n---\n")

    with open('Dormicum_Mobile_Mockup.md', 'w') as f:
        f.write("\n".join(output_lines))
    print("Mobile mockup generated: Dormicum_Mobile_Mockup.md")

if __name__ == "__main__":
    render_mobile_view()
