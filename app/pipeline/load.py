import json
import os
import logging
from sqlalchemy import create_engine, text
# pyrefly: ignore [missing-import]
from ollama import Client



from dotenv import load_dotenv

load_dotenv()

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s - %(levelname)s - %(message)s"
)
_logger = logging.getLogger(__name__)

# ── Cấu hình ──────────────────────────────────────────────
OLLAMA_HOST = os.getenv("OLLAMA_HOST", "http://host.docker.internal:11434")
EMBED_MODEL = "bge-m3"
DB_URL = os.getenv("DATABASE_URL")
INPUT_FILE = os.path.join(os.path.dirname(__file__), "../../data/rag_input_processes_v2.json")
TABLE_NAME = '"Data_Embedding"'

# ── Khởi tạo kết nối ──────────────────────────────────────
engine = create_engine(DB_URL, pool_pre_ping=True)
ollama_client = Client(host=OLLAMA_HOST)


def embed_text(text_content: str) -> list[float]:
    """Gọi Ollama để tạo embedding với model bge-m3."""
    response = ollama_client.embeddings(
        model=EMBED_MODEL,
        prompt=text_content
    )
    return response["embedding"]


def load_and_embed(input_file: str):
    """Đọc JSON, mỗi quy trình = 1 chunk, embed và lưu vào bảng Data_Embedding."""
    with open(input_file, "r", encoding="utf-8") as f:
        processes = json.load(f)

    _logger.info(f"Đọc được {len(processes)} quy trình từ {input_file}")

    with engine.connect() as connection:
        success_count = 0
        skip_count = 0

        for i, process in enumerate(processes):
            process_id = process.get("id", f"unknown_{i}")
            process_name = process.get("process_name", "")
            content = process.get("content", "")

            # Gom các trường phụ vào metadata dạng jsonb
            metadata = {
                "module": process.get("module", ""),
                "actors": process.get("actors", []),
                "precondition": process.get("precondition", ""),
                "tags": process.get("tags", [])
            }

            if not content:
                _logger.warning(f"Bỏ qua {process_id}: không có content.")
                skip_count += 1
                continue

            try:
                # Tạo embedding
                _logger.info(f"Đang embed [{i+1}/{len(processes)}]: {process_id} - {process_name}")
                embedding = embed_text(content)

                # Upsert vào bảng Data_Embedding
                connection.execute(text(f"""
                    INSERT INTO {TABLE_NAME}
                        (process_id, process_name, metadata, content, embedding)
                    VALUES
                        (:process_id, :process_name, CAST(:metadata AS jsonb), :content, CAST(:embedding AS vector))
                    ON CONFLICT (process_id) DO UPDATE SET
                        process_name = EXCLUDED.process_name,
                        metadata     = EXCLUDED.metadata,
                        content      = EXCLUDED.content,
                        embedding    = EXCLUDED.embedding
                """), {
                    "process_id": process_id,
                    "process_name": process_name,
                    "metadata": json.dumps(metadata, ensure_ascii=False),
                    "content": content,
                    "embedding": str(embedding)
                })
                connection.commit()
                success_count += 1

            except Exception as e:
                _logger.error(f"Lỗi khi xử lý {process_id}: {e}")
                connection.rollback()
                raise

    _logger.info(f"Hoàn thành! Thành công: {success_count} | Bỏ qua: {skip_count}")


if __name__ == "__main__":
    _logger.info(f"Bắt đầu embedding với model: {EMBED_MODEL}")
    _logger.info(f"Kết nối Ollama tại: {OLLAMA_HOST}")
    load_and_embed(INPUT_FILE)
