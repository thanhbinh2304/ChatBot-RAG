import os
import json
import logging
from typing import List, Dict

# pyrefly: ignore [missing-import]
from ollama import Client
from sqlalchemy import create_engine, text

# Import retrieve function từ retrieval.py đã có
from app.pipeline.retrieval import retrieve

_logger = logging.getLogger(__name__)

OLLAMA_HOST = os.getenv("OLLAMA_HOST")
ollama_client = Client(host=OLLAMA_HOST)

DB_URL = os.getenv("DATABASE_URL")
engine = create_engine(DB_URL)

# Model chung dùng để phân loại (Router), trả lời RAG và ChitChat
GENERAL_MODEL = os.getenv("ROUTER_MODEL", "qwen2.5:3b") 
# Model dùng để sinh SQL
SQL_MODEL = os.getenv("LLM_MODEL", "hf.co/leebindz/qwen_finetune:Q4_K_M") 

# Lưu trữ lịch sử chat tạm thời trong memory (Dict mapping session_id -> list of messages)
# Trong thực tế nên dùng Redis hoặc Database (PostgreSQL)
CHAT_MEMORY: Dict[str, List[Dict[str, str]]] = {}

# Giới hạn số lượng tin nhắn trong lịch sử (để tránh context quá dài)
MAX_MEMORY_LENGTH = 20 

DB_SCHEMA = """-- BẢNG DỮ LIỆU CỦA HỆ THỐNG GAS TUẤN ĐẠT --
Account(accountId, username, password, status, createdAt, updatedAt, roleId, deleteAt, employeeId) -- Tài khoản người dùng
Area(areaId, areaName) -- Khu vực
CashReceipt(receiptId, receiptDate, receiptAmount, note, customerId, createdBy, transactionTypeId, invoiceId, PaymentMethod, objectId, supplierId, receiptCode, createdDate, employeeId) -- Phiếu thu tiền (Tiền vào)
Customer(customerId, gender, dateOfBirth, note, fullName, phoneNumber, email, wardId, customerGroupId, customerCode, address, debt) -- Khách hàng
CustomerGroup(customerGroupId, groupName) -- Loại khách hàng
Employee(employeeId, employeeCode, positionId, note, status, hireDate, createdAt, updatedAt, gender, dateOfBirth, phoneNumber, fullName, email, wardId) -- Nhân viên
GasBook(gasBookId, gender, dateOfBirth, points, cycles, note, fullName, phoneNumber, email, wardId, cycle, customerGroupid, address, debt, gasBookCode) -- Sổ Gas của khách hàng
Inventory(stockId, productId, quantity, inventoryId) -- Tồn kho hàng hóa
InvoiceDetail(id, quantity, total, unitPrice, invoiceId, productId) -- Chi tiết các mặt hàng trong Hóa đơn bán (SaleInvoice)
Payment(paymentId, paymentDate, paymentAmount, notes, objectId, createdBy, transactionTypeId, purchaseId, stockId, paymentMethod, supplierId, customerId, employeeId, paymentCode) -- Phiếu chi tiền (Tiền ra)
Position(positionId, name) -- Chức vụ nhân viên
PriceList(priceListId, priceListName) -- Bảng giá
Product(productId, productName, unit, cost, categoryId, note, productCode) -- Thông tin sản phẩm / hàng hóa
ProductCategory(categoryId, categoryName) -- Danh mục sản phẩm
PurchaseDetail(purchaseId, productId, quantity, purchasePrice, total, id) -- Chi tiết các mặt hàng trong phiếu nhập
PurchaseOrder(purchaseId, purchaseDate, totalAmount, employeeId, supplierId, note, orderType, stockId, discountAmount, paidAmount, purchaseCode) -- Phiếu nhập hàng / Mua hàng từ nhà cung cấp
SaleInvoice(invoiceId, invoiceDate, totalAmount, discountAmount, paidAmount, note, employeeId, customerId, gasBookId, stockId, orderType, invoiceCode, PaymentMethod) -- Hóa đơn bán hàng / Doanh thu bán hàng
Stock(name, wardId, stockId) -- Cửa hàng / Kho chứa
StockTake(stockTakeId, stockTakeDate, note, employeeId, stockId, stockTakeCode) -- Phiếu kiểm kho
StockTakeDetail(stockTakeId, productId, systymQuantity, actualQuantity, id) -- Chi tiết kiểm kho
StockTransfer(transferId, transferDate, fromStockId, toStockId, employeeId, note, transferCode) -- Phiếu chuyển kho
StockTransferDetail(transferId, productId, quantity, id) -- Chi tiết chuyển kho
Supplier(supplierId, taxNumber, note, fullName, phoneNumber, email, wardId, createdAt, updatedAt, address, debt) -- Nhà cung cấp
Ward(wardId, wardName, areaId) -- Phường/Xã"""


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
    Dùng General Model để phân loại câu hỏi của user (Router).
    Luật phân loại được lấy từ app/Rule/intent_rule.text
    """
    history_str = format_history_for_prompt(history[-4:]) # Lấy 4 tin gần nhất làm ngữ cảnh
    
    # Đọc system prompt từ file Rule/intent_rule.text
    try:
        rule_path = os.path.join(os.path.dirname(__file__), "../Rule/intent_rule.text")
        with open(rule_path, "r", encoding="utf-8") as f:
            system_prompt_content = f.read().strip()
    except Exception as e:
        system_prompt_content = "Chỉ trả về 1 từ: SQL, RAG, hoặc CHAT."

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

def generate_sql(query: str) -> str:
    """
    Sử dụng model đã finetune để sinh ra SQL.
    Ép prompt để chỉ trả về SQL.
    """
    # Dựa vào format lúc bạn finetune (finetune_data.json)
    prompt = f"""Generate PostgreSQL query

### Input:
{DB_SCHEMA}
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

    response = ollama_client.chat(
        model=SQL_MODEL,
        messages=[
            {"role": "system", "content": system_prompt_content},
            {"role": "user", "content": prompt}
        ],
        options={"temperature": 0.0}
    )
    
    sql_query = response['message']['content'].strip()
    # Xử lý clean up nếu model vẫn cố tình sinh markdown
    if sql_query.startswith("```sql"):
        sql_query = sql_query.replace("```sql", "").replace("```", "").strip()
    elif sql_query.startswith("```"):
        sql_query = sql_query.replace("```", "").strip()
        
    return sql_query

def execute_sql(sql_query: str) -> str:
    """
    Thực thi câu lệnh SQL vừa sinh ra vào Database và trả về dữ liệu thô.
    """
    query_upper = sql_query.strip().upper()
    if not query_upper.startswith("SELECT"):
        _logger.warning(f"[Security Block] Không phải SELECT: {sql_query}")
        return "Lỗi truy vấn: Chỉ hỗ trợ tra cứu dữ liệu (SELECT)."
        
    forbidden = ["DROP", "DELETE", "UPDATE", "INSERT", "ALTER", "TRUNCATE", "GRANT", "REVOKE"]
    import re
    for kw in forbidden:
        if re.search(r'\b' + kw + r'\b', query_upper):
            _logger.warning(f"[Security Block] Phát hiện từ khóa {kw}: {sql_query}")
            return "Lỗi truy vấn: Phát hiện từ khóa nguy hiểm."

    try:
        with engine.connect() as conn:
            # SQLAlchemy text() thực thi query
            result = conn.execute(text(sql_query))
            # Trả về list of dicts (json format)
            rows = [dict(row._mapping) for row in result]
            return json.dumps(rows, ensure_ascii=False, default=str)
    except Exception as e:
        _logger.error(f"[Execute SQL] Error: {e}")
        return f"Lỗi truy vấn cơ sở dữ liệu: {e}"

def generate_natural_answer(user_query: str, sql_data: str) -> str:
    """
    Cho LLM đọc cục dữ liệu JSON lấy từ Database và bảo nó trả lời câu hỏi của người dùng.
    """
    # Đọc system prompt từ file Rule/system_instruction.text
    try:
        rule_path = os.path.join(os.path.dirname(__file__), "../Rule/system_instruction.text")
        with open(rule_path, "r", encoding="utf-8") as f:
            system_instruction = f.read().strip()
    except Exception as e:
        system_instruction = "Bạn là chuyên gia phân tích dữ liệu. Hãy trả lời câu hỏi dựa trên JSON."

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
        # Bước A: Sinh SQL
        sql_query = generate_sql(user_query)
        _logger.info(f"[Chat] SQL Generated: {sql_query}")
        sql_executed = sql_query
        
        # Bước B: Chạy SQL lấy cục dữ liệu (JSON)
        raw_db_data = execute_sql(sql_query)
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
        
        res = ollama_client.chat(
            model=GENERAL_MODEL,
            messages=[
                {"role": "system", "content": "Bạn là một trợ lý ảo tiếng Việt hữu ích. Nhiệm vụ của bạn là trả lời câu hỏi DỰA TRÊN ngữ cảnh được cung cấp. BẮT BUỘC trả lời 100% bằng TIẾNG VIỆT, tuyệt đối không sử dụng ngôn ngữ khác."},
                {"role": "user", "content": rag_user_prompt}
            ]
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
                {"role": "system", "content": "Bạn là một trợ lý ảo giao tiếp thân thiện. BẮT BUỘC trả lời 100% bằng TIẾNG VIỆT, tuyệt đối không sử dụng ngôn ngữ khác. Câu trả lời cần ngắn gọn, lịch sự."},
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

