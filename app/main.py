from fastapi import FastAPI
import logging

logging.basicConfig(
    level = logging.INFO,
    format="%(asctime)s - %(levelname)s - %(message)s"
)
app= FastAPI(
    title = "RAG Chatbot",
    description = "Chatbot hỗ trợ trả lời câu hỏi",
    version = "1.0.0"
)

@app.get("/")
def test():
    return {
        "status": "online",
        "message": "Welcome to my Chatbot Gas Tuan Dat!"
        }
