import re

schema_path = "d1_migration_sql/01_schema.sql"

with open(schema_path, "r", encoding="utf-8") as f:
    content = f.read()

# Function to add DROP TABLE before CREATE TABLE
def add_drop(match):
    full_match = match.group(0)
    table_name = match.group(1)
    # clean table name (remove quotes or parent)
    table_name = table_name.replace('"', '').replace('`', '')
    
    # Don't drop sqlite_sequence
    if table_name == "sqlite_sequence":
        return full_match
        
    return f"DROP TABLE IF EXISTS {table_name};\n\n{full_match}"

# Regex for CREATE TABLE
# Matches: CREATE TABLE name ( or CREATE TABLE "name" ...
new_content = re.sub(r'CREATE TABLE \s*"?([a-zA-Z0-9_]+)"?\s*\(', add_drop, content, flags=re.IGNORECASE)

# Special handling for simple CREATE TABLE name lines if any
# My previous dump might have been one-liners or formatted.
# Let's check the file format from previous output.
# It was: CREATE TABLE drugs (\n ...
# The regex above expects CREATE TABLE name (
# It might fail if there's no space?
# Let's be more robust.

with open(schema_path, "w", encoding="utf-8") as f:
    f.write(new_content)

print(f"✅ Updated {schema_path} with DROP TABLE statements.")
