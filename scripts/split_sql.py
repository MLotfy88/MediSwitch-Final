import sys
import os

def split_sql(input_file, rows_per_chunk=1000):
    with open(input_file, 'r', encoding='utf-8') as f:
        lines = f.readlines()

    # Seperate header (DDL) from data (INSERTs)
    # Assuming standard dump where INSERTs start after CREATE statements
    # But checking head, it mixes them. 
    # Let's just split by lines, assuming each INSERT is on a new line and atomic.
    # We will keep the first few lines (DDL) in the first chunk.
    
    # Better strategy: Just simple line splitting, but ensure we don't break multi-line statements if any.
    # The comment says "Single INSERT per drug".
    
    chunk_index = 0
    current_lines = []
    current_count = 0
    
    # Prefix for output files
    base_name = os.path.splitext(input_file)[0]
    
    for line in lines:
        current_lines.append(line)
        if line.strip().upper().startswith('INSERT INTO'):
            current_count += 1
            
        # Check if we reached limit and the line ends with semicolon
        if current_count >= rows_per_chunk and line.strip().endswith(';'):
            output_file = f"{base_name}_part_{chunk_index:03d}.sql"
            with open(output_file, 'w', encoding='utf-8') as out:
                out.writelines(current_lines)
            print(f"Created {output_file} with {len(current_lines)} lines")
            current_lines = []
            current_count = 0
            chunk_index += 1

    # Right remaining lines
    if current_lines:
        output_file = f"{base_name}_part_{chunk_index:03d}.sql"
        with open(output_file, 'w', encoding='utf-8') as out:
            out.writelines(current_lines)
        print(f"Created {output_file} with {len(current_lines)} lines")

if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Usage: python split_sql.py <input_sql_file>")
        sys.exit(1)
    
    split_sql(sys.argv[1], 1500)
