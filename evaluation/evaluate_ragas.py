import os
import sys
import json
import asyncio
from datasets import Dataset
from dotenv import load_dotenv

# Reconfigure stdout for utf-8 on Windows
if sys.stdout.encoding != 'utf-8':
    sys.stdout.reconfigure(encoding='utf-8')

load_dotenv()

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
    print("BẮT ĐẦU QUÁ TRÌNH THU THẬP DỮ LIỆU ĐỂ ĐÁNH GIÁ (RAGAS)")
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
        # Tạo file mẫu nếu chưa có
        sample_data = [
            {
                "question": "Cho tôi biết tổng doanh thu hôm nay",
                "ground_truth": "Tổng doanh thu hôm nay chưa có dữ liệu hoặc theo thông tin trả về là X đồng."
            },
            {
                "question": "Danh sách nhân viên",
                "ground_truth": "Đây là danh sách nhân viên của công ty."
            }
        ]
        with open(test_file_path, "w", encoding="utf-8") as f:
            json.dump(sample_data, f, ensure_ascii=False, indent=4)
        test_data = sample_data

    total_questions = len(test_data)
    print(f"Đã tải {total_questions} câu hỏi từ tập test.\n")

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

        # Lấy answer và contexts có sẵn nếu người dùng đã điền, ngược lại tự động sinh
        if item.get("answer") and item.get("contexts"):
            answer = item["answer"]
            contexts = item["contexts"]
            print("  -> Đã sử dụng answer và contexts có sẵn trong file test_dataset.json")
        else:
            # Lấy Schema rút gọn
            retrieved_schema = get_pruned_schema(question, top_k=5)

            # Sinh SQL -> Chạy DB -> Sinh câu trả lời tự nhiên
            try:
                sql_query, raw_db_data = generate_and_execute_sql_with_retry(question, max_retries=1)
                answer = generate_natural_answer(question, raw_db_data)
            except Exception as e:
                sql_query = "LỖI"
                raw_db_data = ""
                answer = f"Lỗi xử lý: {str(e)}"

            # Context = Schema + SQL + Dữ liệu DB thô
            context_str = (
                f"--- PRUNED SCHEMA ---\n{retrieved_schema}\n\n"
                f"--- GENERATED SQL ---\n{sql_query}\n\n"
                f"--- RAW DB DATA ---\n{raw_db_data}"
            )
            contexts = [context_str]

        data_for_ragas["question"].append(question)
        data_for_ragas["answer"].append(answer)
        data_for_ragas["contexts"].append(contexts)
        # Thêm ground_truth vào list
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
    print("=" * 40)


if __name__ == "__main__":
    if sys.platform.startswith("win"):
        asyncio.set_event_loop_policy(asyncio.WindowsSelectorEventLoopPolicy())
    asyncio.run(run_evaluation())