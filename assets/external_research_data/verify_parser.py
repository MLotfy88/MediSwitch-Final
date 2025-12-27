from bs4 import BeautifulSoup
import json

def clean_text(text):
    if not text:
        return ""
    return " ".join(text.replace("\n", " ").split())

def parse_drug_file(file_path):
    with open(file_path, 'r') as f:
        soup = BeautifulSoup(f.read(), 'html.parser')
    
    data = {"file": file_path}
    table = soup.find('table', class_='table-bordered')
    if table:
        rows = table.find_all('tr')
        for row in rows:
            key_td = row.find('td', class_='key')
            val_td = row.find('td', class_='value')
            if key_td and val_td:
                key = clean_text(key_td.get_text())
                if "ID" == key:
                    data["drug_id"] = clean_text(val_td.get_text())
                elif "Drug Type" in key:
                    data["type"] = clean_text(val_td.get_text())
                elif "Description" in key:
                    data["description"] = clean_text(val_td.get_text())
                elif "ATC Classification" in key:
                    atc_list = []
                    badges = val_td.find_all('span', class_='badge')
                    for b in badges:
                        code = clean_text(b.get_text())
                        hierarchy = b.get('data-tippy-content', "")
                        atc_list.append({"code": code, "hierarchy": hierarchy})
                    data["atc_classifications"] = atc_list
                elif "Useful Links" in key:
                    links = {}
                    a_tags = val_td.find_all('a')
                    for a in a_tags:
                        site = clean_text(a.get_text())
                        href = a.get('href')
                        if site and href:
                            links[site] = href
                    data["external_links"] = links
    return data

def parse_interact_file(file_path):
    with open(file_path, 'r') as f:
        soup = BeautifulSoup(f.read(), 'html.parser')
    
    data = {"file": file_path}
    alert_box = soup.find('div', role='alert')
    if alert_box:
        badges = alert_box.find_all('span', class_='badge')
        for b in badges:
            val = clean_text(b.get_text())
            if val in ["Major", "Moderate", "Minor"]:
                data["severity"] = val
            else:
                data.setdefault("mechanism_tags", []).append(val)

    table = soup.find('table', class_='table-bordered')
    if table:
        rows = table.find_all('tr')
        for row in rows:
            key_td = row.find('td', class_='key')
            val_td = row.find('td', class_='value')
            if key_td and val_td:
                key = clean_text(key_td.get_text())
                if "Interaction" == key:
                    data["interaction_description"] = clean_text(val_td.get_text())
                elif "Management" == key:
                    data["management_advice"] = clean_text(val_td.get_text())
                elif "References" == key:
                    refs = []
                    spans = val_td.find_all('span')
                    for s in spans:
                        refs.append(clean_text(s.get_text()))
                    data["references"] = refs
                elif "Alternative for" in key:
                    drug_name = key.replace("Alternative for", "").strip()
                    alternatives = []
                    a_links = val_td.find_all('a', class_='col-md-2')
                    for a in a_links:
                        alt_name = clean_text(a.get_text())
                        alt_href = a.get('href')
                        if alt_name and alt_href and "drug-detail" in alt_href:
                            alternatives.append({"name": alt_name, "link": alt_href})
                    
                    if "alternatives_drug_a" not in data:
                        data["alternatives_drug_a"] = {"target": drug_name, "list": alternatives}
                    else:
                        data["alternatives_drug_b"] = {"target": drug_name, "list": alternatives}
    return data

if __name__ == "__main__":
    print(json.dumps(parse_drug_file("drug_20.html"), indent=2))
    print(json.dumps(parse_interact_file("interact_2728.html"), indent=2))
