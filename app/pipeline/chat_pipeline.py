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
MAX_MEMORY_LENGTH = 10 

DB_SCHEMA = """Account(accountId, username, password, status, createdAt, updatedAt, roleId, deleteAt, employeeId)
Area(areaId, areaName)
Attribute(attributeId, attributeName)
CashReceipt(receiptId, receiptDate, receiptAmount, note, customerId, createdBy, transactionTypeId, invoiceId, PaymentMethod, objectId, supplierId, receiptCode, createdDate, employeeId)
Customer(customerId, gender, dateOfBirth, note, fullName, phoneNumber, email, wardId, customerGroupId, customerCode, address, debt)
CustomerGroup(customerGroupid, groupName)
Data_Embedding(id, process_id, process_name, metadata, content, embedding)
DebtReceipt(receiptId, debtDate, dueDate, note, receiptCode, status, customerId, gasBookId)
DebtReceiptDetail(id, price, priceList, quantity, receiptId, productId)
Employee(employeeId, employeeCode, positionId, note, status, hireDate, createdAt, updatedAt, gender, dateOfBirth, phoneNumber, fullName, email, wardId)
GasBook(gasBookId, gender, dateOfBirth, points, cycles, note, fullName, phoneNumber, email, wardId, cycle, customerGroupid, address, debt, gasBookCode)
Inventory(stockId, productId, quantity, inventoryId)
InvoiceDetail(id, quantity, total, unitPrice, invoiceId, productId)
Object(objectId, fullName, phoneNumber, address, wardId, email, gender, dateOfBirth)
PasswordChangeVerification(verificationId, accountId, createdAt, employeeEmail, expiresAt, updatedAt, usedAt, username, verificationCodeHash)
PasswordResetRequest(requestId, accountId, approvalToken, createdAt, employeeEmail, processedAt, status, updatedAt, username, CONSTRAINT)
Payment(paymentId, paymentDate, paymentAmount, notes, objectId, createdBy, transactionTypeId, purchaseId, stockId, paymentMethod, supplierId, customerId, employeeId, paymentCode)
Position(positionId, name)
PriceList(priceListId, priceListName)
Product(productId, productName, unit, cost, categoryId, note, productCode)
ProductAttribute(productId, attributeId, attributeValue, id)
ProductCategory(categoryId, categoryName)
ProductPrice(productId, priceListId, sellingPrice, id)
PromotionDetail(id, quantity, productId, promotionId, rewardMilestoneId)
PurchaseDetail(purchaseId, productId, quantity, purchasePrice, total, id)
PurchaseOrder(purchaseId, purchaseDate, totalAmount, employeeId, supplierId, note, orderType, stockId, discountAmount, paidAmount, purchaseCode)
RewardMilestone(promotionId, rewardQuantity, rewardName, promotionName, startDate, endDate, leastValue, value, percentage, notes, promotionCode)
Role(roleId, roleName, description, createdAt, updatedAt, deletedAt)
SaleInvoice(invoiceId, invoiceDate, totalAmount, discountAmount, paidAmount, note, employeeId, customerId, gasBookId, stockId, orderType, invoiceCode, PaymentMethod)
Stock(name, wardId, stockId)
StockTake(stockTakeId, stockTakeDate, note, employeeId, stockId, stockTakeCode)
StockTakeDetail(stockTakeId, productId, systymQuantity, actualQuantity, id)
StockTransfer(transferId, transferDate, fromStockId, toStockId, employeeId, note, transferCode)
StockTransferDetail(transferId, productId, quantity, id)
Supplier(supplierId, taxNumber, note, fullName, phoneNumber, email, wardId, createdAt, updatedAt, address, debt)
Token(tokenId, accountId, refreshToken, expiresAt, createdAt, updatedAt)
TransactionType(transactionTypeId, transactionTypeName)
Ward(wardId, wardName, areaId)"""


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
    Dùng General Model để phân loại câu hỏi của user:
    - Trả về "SQL" nếu câu hỏi liên quan đến tra cứu dữ liệu số liệu (doanh thu, khách hàng, hàng hóa, v.v.)
    - Trả về "RAG" nếu câu hỏi liên quan đến quy trình, hướng dẫn, chính sách.
    - Trả về "CHAT" nếu là câu giao tiếp bình thường.
    """
    history_str = format_history_for_prompt(history[-4:]) # Lấy 4 tin gần nhất làm ngữ cảnh
    
    prompt = f"""Bạn là một hệ thống phân loại câu hỏi (Router). Nhiệm vụ của bạn là đọc câu hỏi của người dùng và lịch sử chat, sau đó phân loại câu hỏi vào 1 trong 3 nhóm sau:
1. SQL: Câu hỏi tra cứu dữ liệu, thống kê, số liệu từ cơ sở dữ liệu (ví dụ: doanh thu hôm nay, khách hàng nợ nhiều nhất, số lượng tồn kho...).
2. RAG: Câu hỏi về quy trình, hướng dẫn sử dụng, chính sách (ví dụ: làm sao để xuất hàng, quy trình đổi gas...).
3. CHAT: Câu hỏi giao tiếp thông thường (chào hỏi, cảm ơn...).

Chỉ trả về 1 từ duy nhất: "SQL", "RAG", hoặc "CHAT". Không giải thích.

Lịch sử gần đây:
{history_str}

Câu hỏi hiện tại: {query}
Phân loại:"""

    response = ollama_client.generate(model=GENERAL_MODEL, prompt=prompt)
    intent = response['response'].strip().upper()
    
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
    
    # Sử dụng system prompt cực ngặt nghèo để tránh giải thích
    response = ollama_client.chat(
        model=SQL_MODEL,
        messages=[
            {"role": "system", "content": "Bạn là máy sinh mã SQL. CHỈ TRẢ VỀ CÂU LỆNH SQL DƯỚI DẠNG TEXT THUẦN, KHÔNG GIẢI THÍCH, KHÔNG DÙNG MARKDOWN BLOCK (```sql)."},
            {"role": "user", "content": prompt}
        ]
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
    prompt = f"""Dưới đây là kết quả trích xuất từ cơ sở dữ liệu (định dạng JSON):
{sql_data}

Dựa vào dữ liệu trên, hãy trả lời câu hỏi của người dùng một cách tự nhiên, ngắn gọn và thân thiện nhất (bằng tiếng Việt). Nếu dữ liệu bị lỗi hoặc rỗng, hãy báo cho người dùng biết.

Câu hỏi: {user_query}
Trả lời:"""
    
    response = ollama_client.generate(model=GENERAL_MODEL, prompt=prompt)
    return response['response'].strip()

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
        
        rag_prompt = f"""Dựa vào thông tin sau để trả lời câu hỏi:
{context}

Lịch sử chat:
{format_history_for_prompt(history[-4:])}

Câu hỏi: {user_query}
Trả lời:"""
        res = ollama_client.generate(model=GENERAL_MODEL, prompt=rag_prompt)
        response_content = res['response'].strip()
        
    else:
        # Chit chat
        chitchat_prompt = f"""Lịch sử chat:
{format_history_for_prompt(history[-4:])}

Câu hỏi: {user_query}
Trả lời thân thiện:"""
        res = ollama_client.generate(model=GENERAL_MODEL, prompt=chitchat_prompt)
        response_content = res['response'].strip()
    
    # 4. Lưu vào memory
    add_message_to_memory(session_id, "user", user_query)
    add_message_to_memory(session_id, "assistant", response_content)
    
    return {
        "intent": intent,
        "response": response_content,
        "sql": sql_executed
    }

