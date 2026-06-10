from app.pipeline.chat_pipeline import generate_sql

query = "kiểm kho chi tiết theo ngày hôm qua"
sql = generate_sql(query)
print(f"Generated SQL: '{sql}'")
