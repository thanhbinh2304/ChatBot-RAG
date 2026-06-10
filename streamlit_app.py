import streamlit as st
import requests
import uuid
import os

# Cấu hình API Backend
API_URL = os.getenv("API_URL", "http://localhost:8090/chat")

# Khởi tạo giao diện trang
st.set_page_config(page_title="Gas Tuấn Đạt AI", page_icon="🔥", layout="centered")
st.title("🤖 Trợ lý ảo Gas Tuấn Đạt")

# Khởi tạo session_id độc nhất cho mỗi user
if "session_id" not in st.session_state:
    st.session_state.session_id = str(uuid.uuid4())

# Khởi tạo lịch sử tin nhắn
if "messages" not in st.session_state:
    st.session_state.messages = []

# Hiển thị các tin nhắn cũ
for msg in st.session_state.messages:
    with st.chat_message(msg["role"]):
        st.markdown(msg["content"])
        
        # Nếu có sinh câu lệnh SQL, hiển thị thêm trong expander
        if "sql" in msg and msg["sql"]:
            with st.expander("🛠️ Xem SQL đã thực thi"):
                st.code(msg["sql"], language="sql")

# Xử lý khi user nhập tin nhắn mới
if prompt := st.chat_input("Bạn muốn hỏi gì về hệ thống?"):
    # Hiển thị tin nhắn của user
    with st.chat_message("user"):
        st.markdown(prompt)
    st.session_state.messages.append({"role": "user", "content": prompt})

    # Hiển thị hiệu ứng đang tải...
    with st.chat_message("assistant"):
        message_placeholder = st.empty()
        message_placeholder.markdown("Đang suy nghĩ... 🤔")
        
        try:
            # Gửi request tới FastAPI backend
            payload = {
                "sessionId": st.session_state.session_id,
                "query": prompt
            }
            
            # (Tùy chọn) Thêm API_KEY vào header nếu bạn có bật xác thực
            headers = {}
            api_key = os.getenv("API_KEY")
            if api_key:
                headers["x-api-key"] = api_key
                
            response = requests.post(API_URL, json=payload, headers=headers)
            response.raise_for_status() # Báo lỗi nếu HTTP status != 200
            
            data = response.json()
            
            reply_text = data.get("response", "Xin lỗi, tôi không thể xử lý câu hỏi này.")
            sql_executed = data.get("sql", None)
            intent = data.get("intent", "UNKNOWN")
            
            # Hiển thị tin nhắn trả lời
            message_placeholder.markdown(reply_text)
            
            # Lưu lại vào lịch sử
            st.session_state.messages.append({
                "role": "assistant", 
                "content": reply_text,
                "sql": sql_executed
            })
            
            # Hiển thị SQL (nếu có)
            if sql_executed:
                with st.expander(f"🛠️ Xem SQL đã thực thi (Intent: {intent})"):
                    st.code(sql_executed, language="sql")
                    
        except Exception as e:
            error_msg = f"Lỗi kết nối tới máy chủ: {e}"
            message_placeholder.error(error_msg)
            st.session_state.messages.append({"role": "assistant", "content": error_msg})
