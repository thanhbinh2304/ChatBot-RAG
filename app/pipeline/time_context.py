from datetime import datetime

def get_current_time_context() -> str:
    """
    Trả về chuỗi thời gian hiện tại bằng tiếng Việt.
    Ví dụ: (Thông tin hệ thống: Hôm nay là Thứ Ba, Ngày 10/06/2026)
    """
    now = datetime.now()
    days = ["Thứ Hai", "Thứ Ba", "Thứ Tư", "Thứ Năm", "Thứ Sáu", "Thứ Bảy", "Chủ Nhật"]
    day_name = days[now.weekday()]
    formatted_date = now.strftime("%d/%m/%Y")
    return f"(Thông tin hệ thống: Hôm nay là {day_name}, Ngày {formatted_date})"
