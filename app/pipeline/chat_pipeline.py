import os
import json
import logging
from typing import List, Dict

# pyrefly: ignore [missing-import]
from ollama import Client

# Import retrieve function từ retrieval.py đã có
from app.pipeline.retrieval import retrieve

# Import các hàm sinh SQL từ module mới
from app.pipeline.sql_generation import generate_and_execute_sql_with_retry, generate_natural_answer
from app.pipeline.time_context import get_current_time_context

_logger = logging.getLogger(__name__)

OLLAMA_HOST = os.getenv("OLLAMA_HOST")
ollama_client = Client(host=OLLAMA_HOST)

# Model chung dùng để phân loại (Router), trả lời RAG và ChitChat
GENERAL_MODEL = os.getenv("ROUTER_MODEL", "qwen2.5:3b") 

# Lưu trữ lịch sử chat tạm thời trong memory (Dict mapping session_id -> list of messages)
# Trong thực tế nên dùng Redis hoặc Database (PostgreSQL)
CHAT_MEMORY: Dict[str, List[Dict[str, str]]] = {}

# Giới hạn số lượng tin nhắn trong lịch sử (để tránh context quá dài)
MAX_MEMORY_LENGTH = 20 



def get_chat_history(session_id: str) -> List[Dict[str, str]]:
    if session_id not in CHAT_MEMORY:
        CHAT_MEMORY[session_id] = []
    return CHAT_MEMORY[session_id]

def add_message_to_memory(session_id: str, role: str, content: str):
    history = get_chat_history(session_id)
    history.append({"role": role, "content": content})
    # Giữ lại MAX_MEMORY_LENGTH tin nhắn gần nhất
    if len(history) > MAX_MEMORY_LENGTH:
        CHAT_MEMORY[session_id] = history[-MAX_MEMORY_LENGTH:]

def format_history_for_prompt(history: List[Dict[str, str]]) -> str:
    formatted = ""
    for msg in history:
        formatted += f"{msg['role'].capitalize()}: {msg['content']}\n"
    return formatted

def classify_intent(query: str, history: List[Dict[str, str]]) -> str:
    """
    Dùng Hybrid Routing: Hard-rule (Regex/Keyword) + LLM (Router).
    Luật phân loại được lấy từ app/Rule/intent_rule.text
    """
    query_lower = query.lower()
    
    # 1. HARD-RULE ROUTING (Fast Path)
    # Lọc các từ khóa RAG rõ ràng (ưu tiên cao)
    rag_keywords = ["quy trình", "hướng dẫn", "chính sách", "quy định", "tài liệu", "sop", "workflow", "cách làm", "cách thực hiện", "điều kiện"]
    if any(k in query_lower for k in rag_keywords):
        _logger.info("[Router] Matched RAG Keyword")
        return "RAG"
        
    # Đọc system prompt từ file Rule/intent_rule.text
    try:
        rule_path = os.path.join(os.path.dirname(__file__), "../Rule/intent_rule.text")
        with open(rule_path, "r", encoding="utf-8") as f:
            system_prompt_content = f.read().strip()
            
        # Parse danh sách từ khóa SQL từ file (những dòng bắt đầu bằng dấu *)
        sql_keywords = []
        for line in system_prompt_content.split('\n'):
            line = line.strip()
            if line.startswith('*') and len(line) < 40 and not line.endswith('?'):
                # Extract keyword (e.g. "* danh sách khách hàng" -> "danh sách khách hàng")
                kw = line[1:].strip().lower()
                if kw:
                    sql_keywords.append(kw)
        
        # Sắp xếp từ khóa dài lên trước để match chính xác cụm từ
        sql_keywords.sort(key=len, reverse=True)
        
        for kw in sql_keywords:
            if kw in query_lower:
                _logger.info(f"[Router] Matched SQL Keyword: '{kw}'")
                return "SQL"
                
    except Exception as e:
        _logger.error(f"[Router] Lỗi đọc rule: {e}")
        system_prompt_content = "Chỉ trả về 1 từ: SQL, RAG, hoặc CHAT."

    # 2. LLM FALLBACK (Slow Path)
    _logger.info("[Router] Falling back to LLM for classification")
    history_str = format_history_for_prompt(history[-4:])
    system_prompt_content = f"{get_current_time_context()}\n{system_prompt_content}"

    user_prompt = f"""Lịch sử gần đây:
{history_str}

Câu hỏi hiện tại: {query}
Phân loại:"""

    response = ollama_client.chat(
        model=GENERAL_MODEL,
        messages=[
            {"role": "system", "content": system_prompt_content},
            {"role": "user", "content": user_prompt}
        ],
        options={"temperature": 0.0}
    )
    
    intent = response['message']['content'].strip().upper()
    
    if "SQL" in intent: return "SQL"
    elif "RAG" in intent: return "RAG"
    return "CHAT"



def chat_pipeline(session_id: str, user_query: str) -> dict:
    _logger.info(f"[Chat] Session {session_id} - Query: {user_query}")
    
    # 1. Lấy lịch sử
    history = get_chat_history(session_id)
    
    # 2. Phân loại
    intent = classify_intent(user_query, history)
    _logger.info(f"[Chat] Intent được phân loại: {intent}")
    
    response_content = ""
    sql_executed = None
    
    # 3. Định tuyến (Router)
    if intent == "SQL":
        # Bước A & B: Sinh SQL, Chạy và Tự sửa lỗi (Reflexion)
        sql_query, raw_db_data = generate_and_execute_sql_with_retry(user_query, max_retries=2)
        _logger.info(f"[Chat] SQL Executed (After Reflection): {sql_query}")
        sql_executed = sql_query
        _logger.info(f"[Chat] Database trả về: {raw_db_data}")
        
        # Bước C: Cho LLM dịch cục JSON thành câu trả lời tự nhiên
        response_content = generate_natural_answer(user_query, raw_db_data)
        
    elif intent == "RAG":
        # Sử dụng hàm retrieve đã có từ retrieval.py
        docs = retrieve(user_query, top_n=3)
        context = "\n\n".join([doc['content'] for doc in docs])
        
        rag_user_prompt = f"""Dựa vào thông tin sau để trả lời câu hỏi:
{context}

Lịch sử chat:
{format_history_for_prompt(history[-4:])}

Câu hỏi: {user_query}"""
        
        try:
            rag_rule_path = os.path.join(os.path.dirname(__file__), "../Rule/rag_instruction.text")
            with open(rag_rule_path, "r", encoding="utf-8") as f:
                rag_system_prompt = f.read().strip()
        except Exception as e:
            _logger.error(f"[RAG] Lỗi đọc rule: {e}")
            rag_system_prompt = "Bạn là trợ lý RAG. Trả lời câu hỏi ngắn gọn dựa trên ngữ cảnh."

        res = ollama_client.chat(
            model=GENERAL_MODEL,
            messages=[
                {"role": "system", "content": f"{get_current_time_context()}\n{rag_system_prompt}"},
                {"role": "user", "content": rag_user_prompt}
            ],
            options={"temperature": 0.0}
        )
        response_content = res['message']['content'].strip()
        
    else:
        # Chit chat
        chitchat_user_prompt = f"""Lịch sử chat:
{format_history_for_prompt(history[-4:])}

Câu hỏi: {user_query}"""
        
        res = ollama_client.chat(
            model=GENERAL_MODEL,
            messages=[
                {"role": "system", "content": f"{get_current_time_context()}\nBạn là một trợ lý ảo giao tiếp thân thiện. BẮT BUỘC trả lời 100% bằng TIẾNG VIỆT, tuyệt đối không sử dụng ngôn ngữ khác. Câu trả lời cần ngắn gọn, lịch sự."},
                {"role": "user", "content": chitchat_user_prompt}
            ]
        )
        response_content = res['message']['content'].strip()
    
    # 4. Lưu vào memory
    add_message_to_memory(session_id, "user", user_query)
    add_message_to_memory(session_id, "assistant", response_content)
    
    return {
        "intent": intent,
        "response": response_content,
        "sql": sql_executed
    }

