import os
import glob

def flatten_rules_file(file_path):
    print(f"Flattening rules in {file_path}...")
    with open(file_path, 'r', encoding='utf-8') as f:
        lines = f.readlines()

    header = ""
    new_lines = []
    
    for line in lines:
        line_stripped = line.strip()
        if not line_stripped:
            continue
            
        if line_stripped.startswith('--'):
            continue
            
        if "INSERT INTO drug_interactions" in line_stripped and "VALUES" in line_stripped:
            header = line_stripped.split("VALUES")[0] + "VALUES"
            header = header.replace('INSERT INTO', 'INSERT OR IGNORE INTO')
            continue
            
        if line_stripped.startswith('('):
            # It's a tuple. It might end with , or ;
            if line_stripped.endswith(','):
                tuple_content = line_stripped[:-1].strip()
            elif line_stripped.endswith(';'):
                tuple_content = line_stripped[:-1].strip()
            else:
                tuple_content = line_stripped
                
            if header:
                new_lines.append(f"{header} {tuple_content};\n")
            else:
                # Should not happen if SQL is well formed
                new_lines.append(line)
        else:
            # Maybe it's part of a multi-line tuple?
            # For simplicity, if it doesn't start with (, we append it to the last line's tuple
            if new_lines and not line_stripped.startswith('INSERT'):
                last_line = new_lines[-1]
                # Remove the trailing ;
                last_line = last_line.strip()[:-1]
                new_lines[-1] = f"{last_line} {line_stripped};\n"
            else:
                new_lines.append(line)

    with open(file_path, 'w', encoding='utf-8') as f:
        f.writelines(new_lines)

if __name__ == "__main__":
    # ONLY rules
    files = glob.glob("../d1_rules_part_*.sql")
    for f in files:
        flatten_rules_file(f)
