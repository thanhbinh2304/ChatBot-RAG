import re
import json

def fix_json_file(filepath):
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()

    # Fix backticks: "output": `...` -> "output": "..."
    def replace_backticks(match):
        inner = match.group(1)
        inner = inner.replace('"', '\\"')
        return f'"output": "{inner}"'
    content = re.sub(r'"output":\s*`([^`]*)`', replace_backticks, content)

    # Fix missing commas between objects
    content = re.sub(r'\}\s*\{', '},\n{', content)

    # Fix smart quotes
    content = content.replace('“', '"').replace('”', '"')
    content = content.replace('‘', "'").replace('’', "'")

    # Fix unescaped quotes inside "output": "..."
    # We match "output": " ... " and escape internal quotes
    def escape_output_quotes(match):
        inner = match.group(1)
        # Only escape if not already escaped
        # A simple way is to replace all " with \", then replace \\" with \"
        inner = inner.replace('\\"', '"').replace('"', '\\"')
        return f'"output": "{inner}"'
    
    # We have to be careful with the regex to capture the whole string.
    # Since output is always the last field in the object, it ends with "\n  }
    # Let's match from "output": " up to "\n  }
    content = re.sub(r'"output":\s*"([\s\S]*?)"\s*\}', lambda m: escape_output_quotes(m) + '\n}', content)
    
    # Wait, the above might not work if there's trailing commas.
    # Let's use a more targeted approach for unescaped quotes in both input and output
    # Actually, a better way is to find each line that starts with "input": "..." or "output": "..."
    # and escape internal quotes.
    lines = content.split('\n')
    for i, line in enumerate(lines):
        if line.strip().startswith('"input": "') and line.endswith('",'):
            prefix = line[:line.find('"input": "') + 10]
            inner = line[line.find('"input": "') + 10:-2]
            inner = inner.replace('\\"', '"').replace('"', '\\"')
            lines[i] = prefix + inner + '",'
        elif line.strip().startswith('"output": "') and line.endswith('"'):
            prefix = line[:line.find('"output": "') + 11]
            inner = line[line.find('"output": "') + 11:-1]
            inner = inner.replace('\\"', '"').replace('"', '\\"')
            lines[i] = prefix + inner + '"'
    content = '\n'.join(lines)
    
    # Clean up some specific typos
    content = content.replace('statu[s', 'status')
    content = content.replace('", ,', '",')
    
    # Fix the trailing ] issue at the end of the file
    content = content.strip()
    while content.endswith(']'):
        content = content[:-1].strip()
    content += '\n]'
    
    # Fix remaining multiple commas
    content = re.sub(r',\s*,', ',', content)
    
    # Try parsing to see if valid
    try:
        data = json.loads(content)
        print("Successfully parsed JSON. Saving...")
        with open(filepath, 'w', encoding='utf-8') as f:
            json.dump(data, f, ensure_ascii=False, indent=2)
    except json.JSONDecodeError as e:
        print(f"Failed to parse JSON: {e}")
        # Save anyway so user can see partial fixes
        with open(filepath, 'w', encoding='utf-8') as f:
            f.write(content)

fix_json_file('data/finetune_data-v2.json')
