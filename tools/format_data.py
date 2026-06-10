import re
import json
import traceback

def process_file(filepath):
    try:
        with open(filepath, 'r', encoding='utf-8') as f:
            content = f.read()

        # Normalize quotes
        content = content.replace('“', '"').replace('”', '"')
        content = content.replace('‘', "'").replace('’', "'")
        
        # Split the file into items by `"instruction":`
        parts = content.split('"instruction":')
        
        new_data = []
        
        for part in parts[1:]:
            # 1. Extract instruction
            instr_match = re.search(r'\s*"([^"]+)"\s*,', part)
            instruction = instr_match.group(1) if instr_match else "Generate PostgreSQL query"
            
            # 2. Extract input
            input_str = ""
            input_start = part.find('"input":')
            if input_start != -1:
                quote_char = None
                start_idx = -1
                for i in range(input_start + 8, len(part)):
                    if part[i] in ['"', '`']:
                        quote_char = part[i]
                        start_idx = i + 1
                        break
                
                if start_idx != -1:
                    output_start = part.find('"output":', start_idx)
                    if output_start != -1:
                        raw_input = part[start_idx:output_start].strip()
                        if raw_input.endswith(','): raw_input = raw_input[:-1].strip()
                        if raw_input.endswith(quote_char): raw_input = raw_input[:-1]
                        raw_input = raw_input.replace('\\"', '"').replace('\\n', '\n')
                        input_str = raw_input
            
            # 3. Extract output
            output_str = ""
            output_start = part.find('"output":')
            if output_start != -1:
                quote_char = None
                start_idx = -1
                for i in range(output_start + 9, len(part)):
                    if part[i] in ['"', '`']:
                        quote_char = part[i]
                        start_idx = i + 1
                        break
                
                if start_idx != -1:
                    last_brace = part.rfind('}')
                    if last_brace != -1:
                        end_idx = part.rfind(quote_char, 0, last_brace)
                    else:
                        end_idx = part.rfind(quote_char)
                    
                    if end_idx != -1 and end_idx >= start_idx:
                        raw_output = part[start_idx:end_idx]
                        raw_output = raw_output.replace('\\"', '"').strip()
                        output_str = raw_output
                        
            # Clean up output string if it has trailing `""`
            if output_str.endswith('""'): output_str = output_str[:-1]
            if output_str.endswith(';""'): output_str = output_str[:-1]
            
            # Parse schema and question
            schema_part = ""
            question_part = ""
            
            if "Question:" in input_str:
                subparts = input_str.split("Question:")
                schema_part = subparts[0].replace("Schema:", "").strip()
                question_part = subparts[1].strip()
            else:
                schema_part = input_str
                
            # If schema_part contains newlines at the end, strip them
            schema_part = schema_part.strip()
                
            new_item = {
                "instruction": instruction,
                "input": {
                    "Schema": schema_part,
                    "Question": question_part
                },
                "output": output_str
            }
            new_data.append(new_item)
            
        with open(filepath, 'w', encoding='utf-8') as f:
            json.dump(new_data, f, ensure_ascii=False, indent=2)
            print(f"Successfully processed {len(new_data)} items and saved to {filepath}!")
            
    except Exception as e:
        print("Error processing file:")
        traceback.print_exc()

process_file('data/finetune_data-v2.json')
process_file('data/finetune_data.json')
