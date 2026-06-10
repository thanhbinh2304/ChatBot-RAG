import os
import sys
import json
import time
import asyncio
from datasets import Dataset
from dotenv import load_dotenv

# Reconfigure stdout for utf-8 on Windows
if sys.stdout.encoding != 'utf-8':
    sys.stdout.reconfigure(encoding='utf-8')

load_dotenv()

# --- FIX LỖI IMPORT CỦA RAGAS VỚI LANGCHAIN MỚI ---
import types
if "langchain_community.chat_models.vertexai" not in sys.modules:
    mock_vertex = types.ModuleType("langchain_community.chat_models.vertexai")
    mock_vertex.ChatVertexAI = type("ChatVertexAI", (object,), {})
    sys.modules["langchain_community.chat_models.vertexai"] = mock_vertex

if "langchain_community.embeddings.vertexai" not in sys.modules:
    mock_embed = types.ModuleType("langchain_community.embeddings.vertexai")
    mock_embed.VertexAIEmbeddings = type("VertexAIEmbeddings", (object,), {})
    sys.modules["langchain_community.embeddings.vertexai"] = mock_embed
# ------------------------------------------------

# pyrefly: ignore [missing-import]
from ragas import evaluate
# pyrefly: ignore [missing-import]
from ragas.run_config import RunConfig
# pyrefly: ignore [missing-import]
from ragas.metrics import Faithfulness, AnswerRelevancy, AnswerCorrectness

# pyrefly: ignore [missing-import]
from langchain_google_genai import ChatGoogleGenerativeAI, GoogleGenerativeAIEmbeddings

# Thêm thư mục gốc vào sys.path để import từ app/pipeline/
current_dir = os.path.dirname(os.path.abspath(__file__))
project_root = os.path.abspath(os.path.join(current_dir, ".."))
if project_root not in sys.path:
    sys.path.insert(0, project_root)

from app.pipeline.sql_generation import generate_and_execute_sql_with_retry, generate_natural_answer
from app.pipeline.schema_pruning import get_pruned_schema


async def run_evaluation():
    print("=" * 60)
    print("BẮT ĐẦU QUÁ TRÌNH THU THẬP DỮ LIỆU ĐỂ ĐÁNH GIÁ ")
    print("=" * 60)

    # Giám khảo: Sử dụng Gemini (gemini-1.5-flash) để đánh giá
    # Yêu cầu phải có biến môi trường GEMINI_API_KEY trong file .env
    judge_llm = ChatGoogleGenerativeAI(model="gemma-4-31b-it", temperature=0)
    judge_embeddings = GoogleGenerativeAIEmbeddings(model="models/gemini-embedding-001")

    # Đọc tập dữ liệu test
    test_file_path = os.path.join(current_dir, "test_dataset.json")
    try:
        with open(test_file_path, "r", encoding="utf-8") as f:
            test_data = json.load(f)
    except FileNotFoundError:
        print(f"Lỗi: Không tìm thấy file dữ liệu tại {test_file_path}")
        print("Tạo file test_dataset.json mẫu...")

    total_questions = len(test_data)
    print(f"Đã tải {total_questions} câu hỏi từ tập test.\n")

    total_latency = 0.0
    latency_measured_count = 0

    # ragas 0.1.21 dùng cột: "question", "answer", "contexts", "ground_truth"
    data_for_ragas = {
        "question": [],
        "answer": [],
        "contexts": [],
        "ground_truth": [] # Thêm cột ground_truth cho metric answer_correctness
    }

    # Chạy thử toàn bộ test_data
    for index, item in enumerate(test_data):
        question = item.get("question", "")
        ground_truth = item.get("ground_truth", "Không có đáp án chuẩn")
        if not question:
            continue

        print(f"[{index + 1}/{total_questions}] Xử lý: {question}")

        start_time = time.perf_counter()

        # LUÔN chạy Bot để kiểm tra xem SQL sinh ra có đúng với ground_truth không
        retrieved_schema = get_pruned_schema(question, top_k=5)
        try:
            sql_query, raw_db_data = generate_and_execute_sql_with_retry(question, max_retries=1)
            # Chúng ta vẫn sinh câu trả lời tự nhiên để bot hoạt động trọn vẹn, 
            # nhưng sẽ KHÔNG lấy nó để Ragas chấm điểm.
            bot_answer = generate_natural_answer(question, raw_db_data)
        except Exception as e:
            sql_query = "LỖI"
            raw_db_data = ""
            bot_answer = f"Lỗi xử lý: {str(e)}"

        # Context = Schema (chỉ đưa schema vào context để giám khảo Ragas đối chiếu logic)
        context_str = f"--- PRUNED SCHEMA ---\n{retrieved_schema}"
        contexts = [context_str]

        latency = time.perf_counter() - start_time
        total_latency += latency
        latency_measured_count += 1
        print(f"  -> Thời gian xử lý: {latency:.2f}s")
        print(f"  -> SQL Bot sinh ra: {sql_query}")

        data_for_ragas["question"].append(question)
        # RẤT QUAN TRỌNG: Đưa câu SQL do bot TỰ SINH RA vào làm 'answer' để đối chiếu với 'ground_truth'
        data_for_ragas["answer"].append(sql_query)
        data_for_ragas["contexts"].append(contexts)
        data_for_ragas["ground_truth"].append(ground_truth)

    dataset = Dataset.from_dict(data_for_ragas)

    print("\n" + "=" * 60)
    print("BẮT ĐẦU CHẤM ĐIỂM VỚI RAGAS (Giám khảo: Gemini-1.5-Flash)...")
    print("=" * 60)

    # Cấu hình RunConfig để tránh TimeoutError với local LLM (giảm concurrency, tăng timeout)
    run_config = RunConfig(timeout=600, max_workers=3, max_retries=3)

    # Thêm answer_correctness vào danh sách đánh giá
    result = evaluate(
        dataset,
        metrics=[Faithfulness(), AnswerRelevancy(strictness=1), AnswerCorrectness()],
        llm=judge_llm,
        embeddings=judge_embeddings,
        run_config=run_config,
    )

    print("\n" + "=" * 40)
    print("    KẾT QUẢ ĐÁNH GIÁ TỔNG QUAN")
    print("=" * 40)
    print(result)
    if latency_measured_count > 0:
        avg_latency = total_latency / latency_measured_count
        print(f"Thời gian phản hồi trung bình (Latency): {avg_latency:.2f}s")
    else:
        print("Thời gian phản hồi trung bình (Latency): N/A (Đã dùng dữ liệu có sẵn)")
    print("=" * 40)


if __name__ == "__main__":
    if sys.platform.startswith("win"):
        asyncio.set_event_loop_policy(asyncio.WindowsSelectorEventLoopPolicy())
    asyncio.run(run_evaluation())