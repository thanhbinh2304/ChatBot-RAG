import streamlit as st
import requests
import uuid
import os

# Cấu hình giao diện Streamlit
st.set_page_config(page_title="AI Chatbot Gas Tuấn Đạt", page_icon="🤖")
st.title("🤖 Trợ lý ảo AI - Gas Tuấn Đạt")

# Lấy cấu hình API
FASTAPI_URL = "http://localhost:8090/chat"
API_KEY = "gastuandat_secret_key_2026"

# Khởi tạo session_id duy nhất cho mỗi phiên duyệt web
if "session_id" not in st.session_state:
    st.session_state.session_id = f"session_{uuid.uuid4().hex[:8]}"

# Khởi tạo lịch sử chat
if "messages" not in st.session_state:
    st.session_state.messages = [
        {"role": "assistant", "content": "Xin chào! Tôi là trợ lý ảo AI. Tôi có thể giúp gì cho bạn hôm nay?"}
    ]

# Hiển thị lịch sử chat lên màn hình
for message in st.session_state.messages:
    with st.chat_message(message["role"]):
        st.markdown(message["content"])

# Xử lý khi người dùng nhập câu hỏi
if prompt := st.chat_input("Nhập câu hỏi của bạn..."):
    # Hiển thị câu hỏi của user
    st.session_state.messages.append({"role": "user", "content": prompt})
    with st.chat_message("user"):
        st.markdown(prompt)

    # Gửi tới FastAPI
    with st.chat_message("assistant"):
        message_placeholder = st.empty()
        message_placeholder.markdown("Đang suy nghĩ...")
        
        try:
            response = requests.post(
                FASTAPI_URL,
                json={
                    "sessionId": st.session_state.session_id,
                    "query": prompt
                },
                headers={
                    "x-api-key": API_KEY,
                    "Content-Type": "application/json"
                },
                timeout=180 # Đợi tối đa 3 phút vì AI chạy trên máy có thể chậm
            )
            
            if response.status_code == 200:
                data = response.json()
                bot_response = data.get("response", "Lỗi không xác định từ AI.")
            elif response.status_code == 401:
                bot_response = "Lỗi: Sai API Key, không có quyền truy cập."
            else:
                bot_response = f"Lỗi hệ thống: {response.status_code}"
                
        except requests.exceptions.ConnectionError:
            bot_response = "Lỗi kết nối: Xin hãy đảm bảo FastAPI (docker-compose) đang chạy ở cổng 8090."
        except requests.exceptions.Timeout:
            bot_response = "AI đang phản hồi quá chậm (quá thời gian chờ)."
            
        message_placeholder.markdown(bot_response)
        st.session_state.messages.append({"role": "assistant", "content": bot_response})
