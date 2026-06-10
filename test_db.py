import os
import sys
sys.stdout.reconfigure(encoding='utf-8')
from sqlalchemy import create_engine, text
from dotenv import load_dotenv

load_dotenv('.env')

DB_URL = os.getenv('DATABASE_URL')
engine = create_engine(DB_URL)
try:
    with engine.connect() as conn:
        rs = conn.execute(text('SELECT process_name, content FROM "Data_Embedding"'))
        for row in rs:
            content = row[1]
            if 'bán hàng khách lẻ' in row[0].lower() or 'bán hàng' in row[0].lower():
                print('--- MATCH FOUND in:', row[0], '---')
                print(content)
except Exception as e:
    print('Error:', e)
