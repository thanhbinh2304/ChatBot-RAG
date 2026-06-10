import os
import json
import time
import pandas as pd
from sqlalchemy import create_engine, text
from dotenv import load_dotenv
from google import genai

# Load biến môi trường từ .env
load_dotenv()

# Tải cấu hình
DB_URL = os.getenv("DATABASE_URL")
if not DB_URL:
    raise ValueError("Chưa cấu hình DATABASE_URL trong .env")

engine = create_engine(DB_URL)

GEMINI_API_KEY = os.environ.get("GEMINI_API_KEY")
if not GEMINI_API_KEY:
    raise ValueError("Chưa cấu hình GEMINI_API_KEY")

# Khởi tạo client Gemini
client = genai.Client(api_key=GEMINI_API_KEY)

# Thêm đường dẫn project vào sys.path để có thể import từ app
import sys
sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from app.pipeline.chat_pipeline import chat_pipeline

def execute_sql_to_df(sql: str) -> pd.DataFrame:
    """Thực thi SQL và trả về Pandas DataFrame."""
    try:
        with engine.connect() as conn:
            return pd.read_sql(text(sql), conn)
    except Exception as e:
        return pd.DataFrame()

def evaluate():
    dataset_path = os.path.join(os.path.dirname(__file__), "test_dataset.json")
    with open(dataset_path, "r", encoding="utf-8") as f:
        dataset = json.load(f)

    total_questions = len(dataset)
    total_exec_acc = 0
    total_faithfulness = 0.0
    total_relevance = 0.0
    total_latency = 0.0

    print(f"\n🚀 BẮT ĐẦU ĐÁNH GIÁ HỆ THỐNG VỚI {total_questions} CÂU HỎI...")
    print("-" * 80)

    for i, item in enumerate(dataset):
        question = item["question"]
        ground_truth_sql = item["ground_truth"]
        
        # 1. Đo thời gian và gọi chatbot hệ thống
        start_time = time.perf_counter()
        session_id = f"eval_session_{i}"
        
        try:
            bot_res = chat_pipeline(session_id, question)
        except Exception as e:
            bot_res = {"response": str(e), "sql": None}
            
        end_time = time.perf_counter()
        
        latency = end_time - start_time
        total_latency += latency
        
        bot_sql = bot_res.get("sql", "")
        bot_answer = bot_res.get("response", "")
        
        # 2. Tính Độ chính xác thực thi (Execution Accuracy)
        gt_df = execute_sql_to_df(ground_truth_sql)
        raw_db_data = gt_df.to_dict(orient="records")
        
        exec_acc = 0
        if bot_sql:
            bot_df = execute_sql_to_df(bot_sql)
            try:
                if gt_df.equals(bot_df):
                    exec_acc = 1
            except Exception:
                pass
                
        total_exec_acc += exec_acc
        
        # 3. Đánh giá Định tính (Trung thực & Liên quan) bằng Gemini
        prompt = f"""Bạn là một giám khảo AI chuyên đánh giá hệ thống RAG/Chatbot.
Dựa vào Câu hỏi, Dữ liệu thô từ Database (đây là sự thật tuyệt đối) và Câu trả lời tự nhiên của chatbot, hãy chấm điểm 2 tiêu chí sau từ 0 đến 1:
1. faithfulness (Tính trung thực): Câu trả lời của chatbot có hoàn toàn dựa vào Dữ liệu thô và không bịa đặt thêm thông tin nào không? (1 = hoàn toàn trung thực, 0 = bịa đặt)
2. answer_relevance (Độ liên quan): Câu trả lời của chatbot có trả lời đúng và trực tiếp vào Câu hỏi không? (1 = cực kỳ liên quan, 0 = không liên quan)

### Input:
- Câu hỏi: {question}
- Dữ liệu thô DB: {json.dumps(raw_db_data, ensure_ascii=False)}
- Câu trả lời của chatbot: {bot_answer}

### Output (Chỉ trả về ĐÚNG MỘT CHUỖI JSON, không chứa markdown, không có bất kỳ văn bản nào khác):
{{"faithfulness": 1.0, "answer_relevance": 1.0}}"""

        try:
            response = client.models.generate_content(
                model='gemini-1.5-flash',
                contents=prompt,
                config={
                    'response_mime_type': 'application/json'
                }
            )
            eval_res = response.text.strip()
            
            # Xử lý dọn dẹp nếu có markdown (đề phòng model vẫn sinh ra)
            if eval_res.startswith("```json"):
                eval_res = eval_res.replace("```json", "").replace("```", "").strip()
            elif eval_res.startswith("```"):
                eval_res = eval_res.replace("```", "").strip()
                
            scores = json.loads(eval_res)
            faithfulness = float(scores.get("faithfulness", 0.0))
            relevance = float(scores.get("answer_relevance", 0.0))
        except Exception as e:
            print(f"  [!] Lỗi khi gọi Gemini ở câu {i+1}: {e}")
            faithfulness = 0.0
            relevance = 0.0
            
        total_faithfulness += faithfulness
        total_relevance += relevance
        
        # In tiến độ
        print(f"Câu {i+1}/{total_questions}: {question}")
        print(f"  → Exec Acc: {exec_acc} | Faithfulness: {faithfulness:.2f} | Relevance: {relevance:.2f} | Latency: {latency:.2f}s")
        print("-" * 80)
        
    # 4. Tổng hợp và in kết quả
    print("\n" + "="*60)
    print("🏆 KẾT QUẢ ĐÁNH GIÁ TỔNG QUAN")
    print("="*60)
    print(f"📌 Tổng số câu hỏi       : {total_questions}")
    print(f"🎯 Độ chính xác thực thi : {(total_exec_acc/total_questions)*100:.2f}%")
    print(f"🛡️  Điểm Trung thực (TB)  : {total_faithfulness/total_questions:.2f} / 1.0")
    print(f"🔗 Điểm Độ liên quan (TB): {total_relevance/total_questions:.2f} / 1.0")
    print(f"⏱️  Latency trung bình    : {total_latency/total_questions:.2f} giây")
    print("="*60 + "\n")

if __name__ == "__main__":
    evaluate()
