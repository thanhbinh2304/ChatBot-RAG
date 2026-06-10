from fastapi import FastAPI, HTTPException, Header, Depends
from pydantic import BaseModel
import logging
import os

API_KEY = os.getenv("API_KEY", "gastuandat_secret_key_2026")

def verify_api_key(x_api_key: str = Header(None)):
    if x_api_key != API_KEY:
        raise HTTPException(status_code=401, detail="Unauthorized")

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

@app.post("/chat", dependencies=[Depends(verify_api_key)])
def chat_endpoint(request: ChatRequest):
    try:
        result = chat_pipeline(request.sessionId, request.query)
        return result
    except Exception as e:
        logging.error(f"Lỗi khi xử lý chat: {e}")
        raise HTTPException(status_code=500, detail=str(e))
