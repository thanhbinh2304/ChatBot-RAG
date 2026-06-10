import re

def parse_sql(file_path):
    with open(file_path, 'r', encoding='utf-8') as f:
        content = f.read()

    tables = {}
    
    # Extract tables and their columns
    create_table_pattern = re.compile(r'CREATE TABLE public\."([^"]+)" \((.*?)\);', re.DOTALL)
    for match in create_table_pattern.finditer(content):
        table_name = match.group(1)
        tables[table_name] = {'columns': [], 'pk': [], 'fk': {}}
        
    # Extract PKs
    pk_pattern = re.compile(r'ALTER TABLE ONLY public\."([^"]+)"\s+ADD CONSTRAINT "[^"]+" PRIMARY KEY \("([^"]+)"\);', re.DOTALL)
    for match in pk_pattern.finditer(content):
        table_name = match.group(1)
        pk_col = match.group(2)
        if table_name in tables:
            tables[table_name]['pk'].append(pk_col)
            
    # Extract FKs
    fk_pattern = re.compile(r'ALTER TABLE ONLY public\."([^"]+)"\s+ADD CONSTRAINT "[^"]+" FOREIGN KEY \("([^"]+)"\) REFERENCES public\."([^"]+)"\("([^"]+)"\);', re.DOTALL)
    for match in fk_pattern.finditer(content):
        table_name = match.group(1)
        fk_col = match.group(2)
        ref_table = match.group(3)
        ref_col = match.group(4)
        if table_name in tables:
            tables[table_name]['fk'][fk_col] = f"{ref_table}.{ref_col}"
            
    return tables

tables_info = parse_sql('GasTuanDat_database.sql')

# Read current FULL_SCHEMA from schema_pruning.py
with open('app/pipeline/schema_pruning.py', 'r', encoding='utf-8') as f:
    lines = f.readlines()

schema_lines = []
in_schema = False
for line in lines:
    if 'FULL_SCHEMA = """' in line:
        in_schema = True
        schema_lines.append(line)
        continue
    if in_schema:
        if '"""' in line:
            schema_lines.append(line)
            break
        schema_lines.append(line)

old_schema_str = "".join(schema_lines)
print("Found old schema")

new_schema_lines = []
for line in schema_lines:
    if line.startswith('--') or '"""' in line or not line.strip():
        new_schema_lines.append(line.strip())
        continue
        
    # parse "TableName(col1, col2) -- Comment"
    match = re.match(r'^([A-Za-z0-9_]+)\((.*?)\)(.*)$', line.strip())
    if match:
        table_name = match.group(1)
        cols_str = match.group(2)
        comment = match.group(3)
        
        cols = [c.strip() for c in cols_str.split(',')]
        new_cols = []
        
        t_info = tables_info.get(table_name, {'pk': [], 'fk': {}})
        for col in cols:
            suffix = ""
            if col in t_info['pk']:
                suffix = " [PK]"
            elif col in t_info['fk']:
                suffix = f" [FK -> {t_info['fk'][col]}]"
            new_cols.append(f"{col}{suffix}")
            
        new_line = f"{table_name}({', '.join(new_cols)}){comment}"
        new_schema_lines.append(new_line)
    else:
        new_schema_lines.append(line.strip())

with open('annotated_schema.txt', 'w', encoding='utf-8') as f:
    f.write("\n".join(new_schema_lines))
print("Successfully wrote annotated schema to annotated_schema.txt")
