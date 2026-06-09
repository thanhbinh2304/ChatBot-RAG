import os
import torch
from transformers import AutoModelForCausalLM, AutoTokenizer, TextStreamer

# =====================================================================
# 1. THÔNG SỐ CẤU HÌNH VÀ TẢI MODEL
# =====================================================================
# Đổi từ bản 1.5B sang bản 0.5B siêu nhẹ cho CPU
MODEL_PATH = "Qwen/Qwen2.5-0.5B-Instruct"
MAX_HISTORY = 20

# System Prompt cố định (KHÔNG lưu vào history, chỉ ghép vào lúc gửi)
system_prompt = {
    "role": "system",
    "content": "Bạn là trợ lý ảo của nhà phân phối Gas Tuấn Đạt. Hãy nói chuyện lịch sự và hỗ trợ khách hàng."
}

print("Đang tải tokenizer...")
# Sử dụng use_fast=False để tránh lỗi tương thích Tokenizer trên Python 3.14
tokenizer = AutoTokenizer.from_pretrained(MODEL_PATH, use_fast=False)

print("Đang tải model vào RAM (CPU)...")
# Ép mô hình chạy hoàn toàn trên CPU để tránh lỗi sập thiếu VRAM/GPU
model = AutoModelForCausalLM.from_pretrained(
    MODEL_PATH,
    torch_dtype=torch.float32,   # Độ chính xác chuẩn phù hợp cho CPU
    device_map={"": "cpu"},
    low_cpu_mem_usage=True       # Ép buộc nạp toàn bộ các tầng layer vào CPU
)

# Sử dụng TextStreamer để in kết quả ra màn hình giống hiệu ứng gõ chữ
streamer = TextStreamer(tokenizer, skip_prompt=True, skip_special_tokens=True)


# =====================================================================
# 2. LOGIC BỘ NHỚ (Sliding Window Memory - BẢO TOÀN DỮ LIỆU)
# =====================================================================
# Khởi tạo mảng lưu trữ TOÀN BỘ lịch sử cuộc trò chuyện.
conversation_history = []


# =====================================================================
# 4. GIAO DIỆN VÀ TƯƠNG TÁC
# =====================================================================
print("\n" + "="*50)
print("🤖 BẮT ĐẦU TRÒ CHUYỆN VỚI TRỢ LÝ GAS TUẤN ĐẠT")
print("Gõ 'quit' để thoát chương trình.")
print("="*50 + "\n")

while True:
    try:
        user_input = input("You: ")
    except (EOFError, KeyboardInterrupt):
        print("\nTạm biệt!")
        break

    if user_input.strip().lower() == 'quit':
        print("Tạm biệt!")
        break
        
    if not user_input.strip():
        continue

    # =====================================================================
    # 3. QUY TRÌNH XỬ LÝ MỖI LƯỢT CHAT
    # =====================================================================
    
    # Bước 1: Thêm input của User vào kho lưu trữ tổng
    conversation_history.append({"role": "user", "content": user_input})
    
    # Bước 2: Dùng Slicing trích xuất tối đa MAX_HISTORY message gần nhất
    recent_history = conversation_history[-MAX_HISTORY:]
    
    # Bước 3: Lắp ráp mảng tạm thời với System Prompt ở đầu
    input_messages = [system_prompt] + recent_history
    
    # Bước 4: Áp dụng chat template chuẩn của model (Qwen)
    prompt_text = tokenizer.apply_chat_template(
        input_messages, 
        tokenize=False, 
        add_generation_prompt=True
    )
    
    # Mã hóa prompt text thành tensor để đưa vào model
    inputs = tokenizer(prompt_text, return_tensors="pt").to(model.device)
    
    print("Assistant: ", end="", flush=True)
    
    # Generate câu trả lời với streaming
    with torch.no_grad():
        outputs = model.generate(
            **inputs,
            max_new_tokens=512,       # Số lượng token sinh ra tối đa
            temperature=0.7,          # Độ sáng tạo
            top_p=0.9,
            streamer=streamer,        # Hỗ trợ in kết quả theo dạng stream
            pad_token_id=tokenizer.eos_token_id
        )
    
    # Trích xuất đoạn text câu trả lời (loại bỏ phần input ban đầu)
    input_length = inputs["input_ids"].shape[1]
    generated_tokens = outputs[0][input_length:]
    reply = tokenizer.decode(generated_tokens, skip_special_tokens=True)
    print() # Xuống dòng sau khi stream xong
    
    # Bước 5: Thêm câu trả lời của Assistant vào kho lưu trữ tổng
    conversation_history.append({"role": "assistant", "content": reply})
    
    # In ra dòng Debug kiểm chứng logic Sliding Window
    print(f"📌 [Debug]: Tổng số message đã lưu: {len(conversation_history)} | Số message gửi lên Qwen: {len(input_messages)}\n")