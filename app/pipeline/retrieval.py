import os
import logging
from sqlalchemy import create_engine, text
# pyrefly: ignore [missing-import]
from ollama import Client
# pyrefly: ignore [missing-import]
from rank_bm25 import BM25Okapi
from sentence_transformers import CrossEncoder

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s - %(levelname)s - %(message)s"
)
_logger = logging.getLogger(__name__)

# ── Cấu hình ──────────────────────────────────────────────
OLLAMA_HOST  = os.getenv("OLLAMA_HOST")
EMBED_MODEL  = "bge-m3"
RERANK_MODEL = "BAAI/bge-reranker-v2-m3"
REWRITING_MODEL    = ("qwen2.5:3b")  # dùng cho query rewriting
DB_URL       = os.getenv("DATABASE_URL")
TABLE_NAME   = '"Data_Embedding"'

VECTOR_TOP_K = 20   # lấy bao nhiêu kết quả từ vector search
BM25_TOP_K   = 20   # lấy bao nhiêu kết quả từ BM25
FINAL_TOP_N  = 5    # trả về bao nhiêu kết quả cuối sau reranking

# ── Khởi tạo ──────────────────────────────────────────────────
engine        = create_engine(DB_URL, pool_pre_ping=True)
ollama_client = Client(host=OLLAMA_HOST)
# CrossEncoder load lười — chỉ khởi tạo khi cần, tránh tốn RAM lúc startup
_cross_encoder: CrossEncoder | None = None

def get_cross_encoder() -> CrossEncoder:
    global _cross_encoder
    if _cross_encoder is None:
        _logger.info(f"[Reranking] Đang load {RERANK_MODEL} từ HuggingFace...")
        _cross_encoder = CrossEncoder(RERANK_MODEL)
        _logger.info("[Reranking] Load xong!")
    return _cross_encoder


# ══════════════════════════════════════════════════════════
# TẦNG 1: QUERY REWRITING
# ══════════════════════════════════════════════════════════
def rewrite_query(original_query: str) -> str:
    """
    Dùng LLM để viết lại query thành câu hỏi rõ ràng,
    phù hợp hơn cho việc tìm kiếm thông tin trong hệ thống quản lý Gas.
    """
    _logger.info(f"[Query Rewriting] Query gốc: {original_query}")

    # Đọc prompt từ file Rule/rewriting_rule.text
    try:
        rule_path = os.path.join(os.path.dirname(__file__), "../Rule/rewriting_rule.text")
        with open(rule_path, "r", encoding="utf-8") as f:
            prompt_template = f.read().strip()
    except Exception as e:
        _logger.error(f"[Query Rewriting] Không thể đọc file rule: {e}")
        prompt_template = "Viết lại câu hỏi sau: {original_query}"

    prompt = prompt_template.replace("{original_query}", original_query)

    response = ollama_client.chat(
        model=REWRITING_MODEL,
        messages=[{"role": "user", "content": prompt}],
        options={"temperature": 0.0}
    )
    rewritten = response["message"]["content"].strip()
    _logger.info(f"[Query Rewriting] Query sau rewrite: {rewritten}")
    return rewritten


# ══════════════════════════════════════════════════════════
# TẦNG 2: HYBRID SEARCH (Vector + BM25)
# ══════════════════════════════════════════════════════════
def load_all_documents() -> list[dict]:
    """Load toàn bộ documents từ DB để phục vụ BM25."""
    with engine.connect() as conn:
        result = conn.execute(text(f"""
            SELECT id, process_id, process_name, metadata, content
            FROM {TABLE_NAME}
        """))
        return [row._mapping for row in result]


def vector_search(query: str, top_k: int = VECTOR_TOP_K) -> list[dict]:
    """Tìm kiếm bằng vector similarity (cosine) trong pgvector."""
    _logger.info(f"[Vector Search] Đang tìm top {top_k} kết quả...")

    # Embed câu truy vấn
    response = ollama_client.embeddings(model=EMBED_MODEL, prompt=query)
    query_embedding = response["embedding"]

    with engine.connect() as conn:
        result = conn.execute(text(f"""
            SELECT id, process_id, process_name, metadata, content,
                   1 - (embedding <=> CAST(:query_embedding AS vector)) AS score
            FROM {TABLE_NAME}
            ORDER BY embedding <=> CAST(:query_embedding AS vector)
            LIMIT :top_k
        """), {
            "query_embedding": str(query_embedding),
            "top_k": top_k
        })
        docs = [dict(row._mapping) for row in result]

    _logger.info(f"[Vector Search] Tìm được {len(docs)} kết quả")
    return docs


def bm25_search(query: str, all_docs: list[dict], top_k: int = BM25_TOP_K) -> list[dict]:
    """Tìm kiếm bằng BM25 trên toàn bộ corpus."""
    _logger.info(f"[BM25 Search] Đang tìm top {top_k} kết quả...")

    # Tokenize đơn giản bằng cách tách theo dấu cách (phù hợp tiếng Việt không có dấu cách từ)
    tokenized_corpus = [doc["content"].lower().split() for doc in all_docs]
    bm25 = BM25Okapi(tokenized_corpus)

    tokenized_query = query.lower().split()
    scores = bm25.get_scores(tokenized_query)

    # Sắp xếp và lấy top_k
    scored_docs = sorted(
        zip(scores, all_docs),
        key=lambda x: x[0],
        reverse=True
    )[:top_k]

    results = []
    for score, doc in scored_docs:
        doc_copy = dict(doc)
        doc_copy["score"] = float(score)
        results.append(doc_copy)

    _logger.info(f"[BM25 Search] Tìm được {len(results)} kết quả")
    return results


def reciprocal_rank_fusion(
    vector_results: list[dict],
    bm25_results: list[dict],
    k: int = 60
) -> list[dict]:
    """
    Kết hợp kết quả Vector Search và BM25 bằng Reciprocal Rank Fusion (RRF).
    RRF score = 1/(rank + k) cho mỗi list, sau đó cộng lại.
    """
    _logger.info("[RRF] Đang kết hợp kết quả Vector + BM25...")

    rrf_scores: dict[str, float] = {}
    doc_map: dict[str, dict] = {}

    # Tính RRF score từ vector results
    for rank, doc in enumerate(vector_results):
        doc_id = str(doc["process_id"])
        rrf_scores[doc_id] = rrf_scores.get(doc_id, 0) + 1 / (rank + k)
        doc_map[doc_id] = doc

    # Tính RRF score từ BM25 results
    for rank, doc in enumerate(bm25_results):
        doc_id = str(doc["process_id"])
        rrf_scores[doc_id] = rrf_scores.get(doc_id, 0) + 1 / (rank + k)
        doc_map[doc_id] = doc

    # Sắp xếp theo RRF score giảm dần
    sorted_ids = sorted(rrf_scores, key=lambda x: rrf_scores[x], reverse=True)
    merged = []
    for doc_id in sorted_ids:
        doc = dict(doc_map[doc_id])
        doc["rrf_score"] = rrf_scores[doc_id]
        merged.append(doc)

    _logger.info(f"[RRF] Sau fusion: {len(merged)} documents duy nhất")
    return merged


# ══════════════════════════════════════════════════════════
# TẦNG 3: RERANKING (bge-rerank-v2-m3 via sentence-transformers)
# ══════════════════════════════════════════════════════════
def rerank(query: str, candidates: list[dict], top_n: int = FINAL_TOP_N) -> list[dict]:
    """
    Rerank bằng CrossEncoder BAAI/bge-reranker-v2-m3 load từ HuggingFace.
    Không cần Ollama hỗ trợ reranking.
    """
    _logger.info(f"[Reranking] Reranking {len(candidates)} candidates với {RERANK_MODEL}...")

    cross_encoder = get_cross_encoder()

    # Tạo các cặp (query, document_content)
    pairs = [(query, doc["content"]) for doc in candidates]
    scores = cross_encoder.predict(pairs)

    # Sắp xếp theo score giảm dần, lấy top_n
    scored = sorted(zip(scores, candidates), key=lambda x: x[0], reverse=True)

    results = []
    for score, doc in scored[:top_n]:
        if score < 0.3:
            _logger.info(f"[Reranking] Bỏ qua '{doc.get('process_name')}' do điểm quá thấp ({score:.4f})")
            continue
            
        doc_copy = dict(doc)
        doc_copy["rerank_score"] = float(score)
        results.append(doc_copy)

    _logger.info(f"[Reranking] Trả về top {len(results)} kết quả cuối")
    return results


# ══════════════════════════════════════════════════════════
# PIPELINE CHÍNH
# ══════════════════════════════════════════════════════════
def retrieve(query: str, top_n: int = FINAL_TOP_N) -> list[dict]:
    """
    Pipeline RAG đầy đủ:
    1. Query Rewriting  (Qwen 3.5 4B Q4)
    2. Hybrid Search    (Vector pgvector + BM25 + RRF)
    3. Reranking        (Qwen 3.5 4B Q4 — Listwise)
    """
    _logger.info(f"{'='*50}")
    _logger.info(f"[Retrieval] Bắt đầu với query: {query}")

    # Tầng 1: Rewrite query
    rewritten_query = rewrite_query(query)

    # Tầng 2: Hybrid Search
    all_docs = load_all_documents()
    vector_results = vector_search(rewritten_query)
    bm25_results   = bm25_search(rewritten_query, all_docs)
    candidates     = reciprocal_rank_fusion(vector_results, bm25_results)

    if not candidates:
        _logger.warning("[Retrieval] Không tìm thấy kết quả nào!")
        return []

    # Tầng 3: Reranking
    final_results = rerank(rewritten_query, candidates, top_n=top_n)

    _logger.info(f"[Retrieval] Hoàn thành. Trả về {len(final_results)} kết quả.")
    return final_results


# ── Test thử ───────────────────────────────────────────────
if __name__ == "__main__":
    test_query = "làm thế nào để đặt hàng xuất?"
    results = retrieve(test_query)

    print(f"\n{'='*50}")
    print(f"KẾT QUẢ cho query: '{test_query}'")
    print(f"{'='*50}")
    for i, doc in enumerate(results, 1):
        print(f"\n[{i}] {doc['process_name']} (score: {doc.get('rerank_score', 0):.4f})")
        print(f"    Process ID: {doc['process_id']}")
        print(f"    Nội dung: {doc['content'][:200]}...")
