# Trợ lý ảo ChatBot-RAG (Gas Tuấn Đạt) 🤖🔥

Dự án Hệ thống AI tương tác thông minh (Hybrid Conversational AI) được xây dựng chuyên biệt cho hệ thống quản lý của Gas Tuấn Đạt. 
Hệ thống kết hợp nhiều luồng xử lý NLP hiện đại bao gồm tự động phân loại ý định (Intent Routing), truy xuất tài liệu (RAG), và tự động tạo - thực thi truy vấn cơ sở dữ liệu (Text-to-SQL) hoàn toàn bằng tiếng Việt.

## ✨ Tính năng nổi bật

*   **Router Ý định Thông minh (Intent Routing)**: Tự động phân loại câu hỏi của người dùng thành các luồng `SQL` (truy vấn số liệu), `RAG` (hỏi đáp quy trình/văn bản), hoặc `CHAT` (giao tiếp thông thường).
*   **Pipeline Text-to-SQL Tự động**: 
    *   Tự động sinh câu lệnh SQL từ ngôn ngữ tự nhiên (tiếng Việt).
    *   Tối ưu hóa bảng dữ liệu đầu vào (Dynamic Schema Pruning) giúp LLM không bị quá tải.
    *   Cơ chế Tự động sửa lỗi (Self-Correction / Retry) nếu câu truy vấn sinh ra gặp lỗi khi thực thi trên CSDL.
*   **Pipeline Hybrid RAG**: 
    *   Kết hợp tìm kiếm ngữ nghĩa Vector Search (thông qua `pgvector`) và tìm kiếm từ khóa Lexical Search (`BM25`).
    *   Sử dụng Reciprocal Rank Fusion (RRF) để gộp kết quả.
    *   Sử dụng Cross-Encoder Reranker (`bge-rerank-v2-m3`) để đánh giá và xếp hạng lại các tài liệu sao cho sát với câu hỏi nhất.
*   **Giao diện Web Trực quan**: Tích hợp frontend xây dựng bằng Streamlit, hỗ trợ xem trực tiếp các câu lệnh SQL đã được LLM sinh ra và thực thi ẩn bên dưới.
*   **Triển khai linh hoạt**: Đã được thiết lập sẵn `Dockerfile` và `docker-compose.yml` để dễ dàng đóng gói và deploy.

## 🛠️ Công nghệ sử dụng

*   **Backend Framework**: FastAPI, Uvicorn
*   **Frontend**: Streamlit
*   **Cơ sở dữ liệu**: PostgreSQL (kết hợp `pgvector`), SQLAlchemy, psycopg2.
*   **Mô hình AI (LLMs & Embeddings)**: 
    *   Local LLM: `Qwen` (bản fine-tuned `qwen3-4b-instruct-2507`) chạy qua Ollama.
    *   Đánh giá (Evaluator): Sử dụng `Gemma-4-31b-it` / `Gemini` qua API Google Generative AI.
    *   Reranker: `bge-rerank-v2-m3`.
*   **Frameworks khác**: `langchain`, `rank_bm25`, `sentence-transformers`.
*   **Kiểm thử & Đánh giá**: `Ragas` framework.

## ⚙️ Yêu cầu hệ thống (Prerequisites)

*   Python 3.10+
*   PostgreSQL (Bắt buộc phải cài đặt extension `pgvector`)
*   Ollama (cài đặt và chạy model local theo Modelfile)
*   Docker & Docker Compose (tùy chọn)

## 🚀 Hướng dẫn cài đặt

**1. Clone dự án và cài đặt thư viện:**
```bash
git clone <repository_url>
cd ChatBot-RAG
pip install -r requirements.txt
```

**2. Thiết lập cơ sở dữ liệu:**
*   Tạo database PostgreSQL.
*   Khôi phục (Restore) database từ file `GasTuanDat_database.sql` đính kèm.

**3. Thiết lập biến môi trường:**
Tạo hoặc chỉnh sửa file `.env` ở thư mục gốc với các thông số:
```env
# URL kết nối Database
DATABASE_URL=postgresql://<username>:<password>@localhost:5432/<dbname>

# Cấu hình Ollama cho Local LLM
OLLAMA_HOST=http://localhost:11434

# API Key để đánh giá bằng Google GenAI
GEMINI_API_KEY=your_google_api_key_here
```

## 🎮 Hướng dẫn sử dụng

### Chạy trực tiếp với Python
**1. Khởi động Backend (FastAPI):**
```bash
uvicorn app.main:app --host 0.0.0.0 --port 8090 --reload
```
API lúc này sẽ lắng nghe tại `http://localhost:8090/`. Bạn có thể truy cập `http://localhost:8090/docs` để xem tài liệu Swagger.

**2. Khởi động Frontend (Streamlit):**
Mở một terminal mới và chạy:
```bash
streamlit run streamlit_app.py
```
Giao diện chat sẽ tự động mở ra trên trình duyệt (thường ở cổng 8501).

### Chạy bằng Docker
Hệ thống hỗ trợ chạy backend bằng Docker Compose một cách dễ dàng:
```bash
docker-compose up -d --build
```

## 📂 Cấu trúc dự án
```text
ChatBot-RAG/
├── app/                  # Mã nguồn chính của Backend FastAPI
│   ├── main.py           # Entry point của FastAPI
│   ├── pipeline/         # Các luồng xử lý chính: RAG, Text-to-SQL, Router
│   └── Rule/             # Chứa các file cấu hình, prompt rules (.text)
├── data/                 # Thư mục lưu trữ tài liệu dữ liệu thô
├── evaluation/           # Các script đánh giá chất lượng (Ragas)
│   └── evaluate_system.py 
├── fine_tune/            # Dữ liệu và script liên quan đến việc Fine-tune mô hình
├── tools/                # Công cụ phụ trợ
├── .env                  # Cấu hình biến môi trường
├── docker-compose.yml    # File triển khai Docker Compose
├── Dockerfile            # Cấu hình image Docker cho backend
├── GasTuanDat_database.sql # Database backup (Schema + Data)
├── requirements.txt      # Các thư viện phụ thuộc
├── schema.txt            # Document lưu trữ Cấu trúc lược đồ CSDL
└── streamlit_app.py      # Giao diện Frontend bằng Streamlit
```

## 📊 Đánh giá chất lượng hệ thống (Evaluation)
Hệ thống cung cấp một script dùng để kiểm thử độ chính xác định lượng, kết hợp giữa `test_dataset.json` và bộ thư viện `Ragas`. Quá trình kiểm thử đánh giá ba chỉ số chính của Pipeline NLP: `Faithfulness`, `Answer Relevancy` và `Answer Correctness`.

Để chạy đánh giá toàn bộ Pipeline:
```bash
python evaluation/evaluate_system.py
```

## 📜 Giấy phép (License)
Dự án được phát triển nội bộ. All rights reserved.
