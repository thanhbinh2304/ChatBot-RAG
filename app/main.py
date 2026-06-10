from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
import logging

from app.pipeline.chat_pipeline import chat_pipeline

logging.basicConfig(
    level = logging.INFO,
    format="%(asctime)s - %(levelname)s - %(message)s"
)
app= FastAPI(
    title = "RAG Chatbot",
    description = "Chatbot hỗ trợ trả lời câu hỏi",
    version = "1.0.0"
)

class ChatRequest(BaseModel):
    sessionId: str
    query: str

@app.get("/")
def test():
    return {
        "status": "online",
        "message": "Welcome to my Chatbot Gas Tuan Dat!"
        }

@app.post("/chat")
def chat_endpoint(request: ChatRequest):
    try:
        result = chat_pipeline(request.sessionId, request.query)
        return result
    except Exception as e:
        logging.error(f"Lỗi khi xử lý chat: {e}")
        raise HTTPException(status_code=500, detail=str(e))
