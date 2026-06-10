import os
import json
import logging
import re
from datetime import datetime

from app.pipeline.time_context import get_current_time_context

# pyrefly: ignore [missing-import]
from ollama import Client
from sqlalchemy import create_engine, text

from app.pipeline.schema_pruning import get_pruned_schema

_logger = logging.getLogger(__name__)

OLLAMA_HOST = os.getenv("OLLAMA_HOST")
ollama_client = Client(host=OLLAMA_HOST)

DB_URL = os.getenv("DATABASE_URL")
engine = create_engine(DB_URL)

GENERAL_MODEL = os.getenv("ROUTER_MODEL", "qwen2.5:3b") 
SQL_MODEL = os.getenv("LLM_MODEL", "hf.co/leebindz/qwen_finetune:Q4_K_M") 

def generate_sql(query: str) -> str:
    """
    Sử dụng model đã finetune để sinh ra SQL.
    Ép prompt để chỉ trả về SQL.
    """
    # Sử dụng Schema Pruning để chỉ lấy các bảng liên quan nhất (top 5)
    pruned_schema = get_pruned_schema(query, top_k=5)
    # Dựa vào format lúc bạn finetune (finetune_data.json)
    prompt = f"""Generate PostgreSQL query

### Input:
{pruned_schema}
Question: {query}

### Output:
"""
    
    # Đọc system prompt từ file Rule/system_rule.text
    try:
        rule_path = os.path.join(os.path.dirname(__file__), "../Rule/system_rule.text")
        with open(rule_path, "r", encoding="utf-8") as f:
            system_prompt_content = f.read().strip()
    except Exception as e:
        system_prompt_content = "Bạn là chuyên gia SQL. Chỉ sinh SQL."

    # Bơm thời gian thực vào system_prompt
    system_prompt_content = f"{get_current_time_context()}\n{system_prompt_content}"

    response = ollama_client.chat(
        model=SQL_MODEL,
        messages=[
            {"role": "system", "content": system_prompt_content},
            {"role": "user", "content": prompt}
        ],
        options={"temperature": 0.0}
    )
    
    sql_query = response['message']['content'].strip()
    if sql_query.startswith("```sql"):
        sql_query = sql_query.replace("```sql", "").replace("```", "").strip()
    elif sql_query.startswith("```"):
        sql_query = sql_query.replace("```", "").strip()
        
    return sql_query

def fix_sql(query: str, wrong_sql: str, error_msg: str) -> str:
    """
    Yêu cầu LLM sửa lại câu SQL bị lỗi (Reflexion).
    """
    pruned_schema = get_pruned_schema(query, top_k=5)
    
    prompt = f"""You are a PostgreSQL expert. The following SQL query failed with an error.
Please fix the SQL query based on the database schema and the error message.

### Database Schema:
{pruned_schema}

### User Question:
{query}

### Wrong SQL Query:
{wrong_sql}

### PostgreSQL Error Message:
{error_msg}

### Fixed SQL Query (Respond ONLY with the valid SQL query code, no explanations):
"""
    system_prompt_content = f"{get_current_time_context()}\nBạn là chuyên gia PostgreSQL. Nhiệm vụ của bạn là sửa lỗi câu lệnh SQL. Chỉ trả về cú pháp SQL duy nhất, không giải thích hay dùng markdown block."
    
    response = ollama_client.chat(
        model=SQL_MODEL,
        messages=[
            {"role": "system", "content": system_prompt_content},
            {"role": "user", "content": prompt}
        ],
        options={"temperature": 0.0}
    )
    
    sql_query = response['message']['content'].strip()
    if sql_query.startswith("```sql"):
        sql_query = sql_query.replace("```sql", "").replace("```", "").strip()
    elif sql_query.startswith("```"):
        sql_query = sql_query.replace("```", "").strip()
        
    return sql_query

def execute_sql_internal(sql_query: str) -> tuple[bool, str]:
    """
    Thực thi câu lệnh SQL vừa sinh ra vào Database.
    Trả về (is_success, result_json_or_error_message).
    """
    query_upper = sql_query.strip().upper()
    if not query_upper.startswith("SELECT"):
        return False, "Lỗi truy vấn: Chỉ hỗ trợ tra cứu dữ liệu (SELECT)."
        
    forbidden = ["DROP", "DELETE", "UPDATE", "INSERT", "ALTER", "TRUNCATE", "GRANT", "REVOKE"]
    for kw in forbidden:
        if re.search(r'\b' + kw + r'\b', query_upper):
            return False, f"Lỗi truy vấn: Phát hiện từ khóa nguy hiểm {kw}."

    try:
        with engine.connect() as conn:
            result = conn.execute(text(sql_query))
            rows = [dict(row._mapping) for row in result]
            return True, json.dumps(rows, ensure_ascii=False, default=str)
    except Exception as e:
        return False, str(e)

def generate_and_execute_sql_with_retry(query: str, max_retries: int = 2) -> tuple[str, str]:
    """
    Hàm pipeline kết hợp: Sinh SQL -> Chạy thử -> Tự sửa lỗi (nếu có).
    Trả về (final_sql_query, data_or_error_message)
    """
    sql_query = generate_sql(query)
    
    for attempt in range(max_retries + 1):
        success, raw_db_data = execute_sql_internal(sql_query)
        if success:
            return sql_query, raw_db_data
        
        if attempt < max_retries:
            _logger.warning(f"[Auto-Correction] Attempt {attempt + 1}/{max_retries} failed. Error: {raw_db_data}. Fixing...")
            sql_query = fix_sql(query, sql_query, raw_db_data)
        else:
            _logger.error(f"[Auto-Correction] Failed after {max_retries} retries. Last error: {raw_db_data}")
            return sql_query, f"Lỗi truy vấn cơ sở dữ liệu sau {max_retries} lần tự sửa: {raw_db_data}"

def generate_natural_answer(user_query: str, sql_data: str) -> str:
    """
    Cho LLM đọc cục dữ liệu JSON lấy từ Database và bảo nó trả lời câu hỏi của người dùng.
    """
    try:
        rule_path = os.path.join(os.path.dirname(__file__), "../Rule/system_instruction.text")
        with open(rule_path, "r", encoding="utf-8") as f:
            system_instruction = f.read().strip()
    except Exception as e:
        system_instruction = "Bạn là chuyên gia phân tích dữ liệu. Hãy trả lời câu hỏi dựa trên JSON."

    system_instruction = f"{get_current_time_context()}\n{system_instruction}"

    user_prompt = f"""Dưới đây là kết quả trích xuất từ cơ sở dữ liệu (định dạng JSON):
{sql_data}

Dựa vào dữ liệu trên, hãy trả lời câu hỏi sau:
Câu hỏi: {user_query}"""

    response = ollama_client.chat(
        model=GENERAL_MODEL,
        messages=[
            {"role": "system", "content": system_instruction},
            {"role": "user", "content": user_prompt}
        ],
        options={"temperature": 0.0}
    )
    return response['message']['content'].strip()
