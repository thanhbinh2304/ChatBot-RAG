import re

schema = []
current_table = None
columns = []

with open('GasTuanDat_database.sql', 'r', encoding='utf-8') as f:
    for line in f:
        line = line.strip()
        
        if line.startswith('CREATE TABLE'):
            # CREATE TABLE public."Account" (
            match = re.search(r'CREATE TABLE (?:public\.)?\"?([^\"]+)\"? \((.*)', line)
            if match:
                current_table = match.group(1)
                columns = []
                continue
        elif line.startswith('CREATE TABLE'): # For no quotes
             match = re.search(r'CREATE TABLE (?:public\.)?([^\(]+)\s*\(', line)
             if match:
                current_table = match.group(1).strip()
                columns = []
                continue

        if current_table and line == ');':
            schema.append(f"{current_table}({', '.join(columns)})")
            current_table = None
            columns = []
            continue

        if current_table and line and not line.startswith('--') and not line.startswith('(') and not line.startswith(')'):
            # Extract column name
            col_match = re.search(r'^\"?([a-zA-Z0-9_]+)\"?\s+', line)
            if col_match:
                columns.append(col_match.group(1))

with open('schema.txt', 'w', encoding='utf-8') as f_out:
    for s in schema:
        f_out.write(s + '\n')
