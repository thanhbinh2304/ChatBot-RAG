from app.pipeline.chat_pipeline import chat_pipeline
import logging

logging.basicConfig(level=logging.INFO)

query = "Tác nhân trong quy trình bán hàng khách lẻ là ai?"
res = chat_pipeline("test-session", query)
print(f"Chat pipeline output: {res}")
