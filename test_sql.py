from app.pipeline.chat_pipeline import generate_sql
import logging

logging.basicConfig(level=logging.INFO)

query = "doanh thu tháng 5"
sql = generate_sql(query)
print(f"Generated SQL: '{sql}'")
