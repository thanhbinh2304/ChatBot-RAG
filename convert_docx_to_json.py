import json
from docx import Document
import re

def convert():
    doc = Document("Quy trình nghiệp vụ.docx")
    processes = []
    
    # Chúng ta giả định mỗi bảng đại diện cho một quy trình
    for i, t in enumerate(doc.tables):
        try:
            # Lấy tiêu đề quy trình từ hàng số 0
            title_text = t.rows[0].cells[0].text.strip()
            if not title_text.lower().startswith("mô tả tổng quát"):
                continue
                
            process_name = re.sub(r'(?i)^mô tả tổng quát\s+', '', title_text)
            process_name = process_name[0].upper() + process_name[1:]
            
            # Lấy thông tin tác nhân từ hàng số 2
            actors_text = t.rows[2].cells[0].text.strip()
            actors_str = re.sub(r'(?i)^đối tượng thực hiện:\s*', '', actors_text)
            actors = [a.strip().capitalize() for a in actors_str.split(',') if a.strip()]
            
            # Phân loại module dựa trên tên quy trình
            module = "Chưa phân loại"
            if "bán hàng" in process_name.lower(): module = "Bán hàng"
            elif "nhập hàng" in process_name.lower() or "tại kho" in process_name.lower() or "điều chuyển" in process_name.lower(): module = "Kho hàng"
            elif "tại cửa hàng" in process_name.lower(): module = "Cửa hàng"
            elif "công nợ" in process_name.lower(): module = "Công nợ"
            
            # Lấy thông tin điều kiện đầu vào từ hàng số 3
            precond_text = t.rows[3].cells[0].text.strip()
            precondition = re.sub(r'(?i)^điều kiện bắt đầu:\s*', '', precond_text)
            
            # Lấy thông tin kết quả đầu ra từ hàng số 5
            results_text = t.rows[5].cells[0].text.strip()
            results = re.sub(r'(?i)^kết quả đầu ra:\s*', '', results_text)
            
            # Đọc luồng sự kiện chính từ hàng số 11 trở đi
            events = []
            for row_idx in range(11, len(t.rows)):
                stt = t.rows[row_idx].cells[0].text.strip()
                actor = t.rows[row_idx].cells[1].text.strip()
                content = t.rows[row_idx].cells[2].text.strip()
                if stt and content:
                    # Làm sạch nội dung (ví dụ: chuyển các dấu gạch đầu dòng \n· thành dấu chấm)
                    content_clean = content.replace('\n·', '. ').replace('\n', ' ')
                    content_clean = re.sub(r'\s+\.', '.', content_clean)
                    
                    if actor:
                        # Thỉnh thoảng tác nhân đã được ghi chú ngay ở đầu dòng nội dung
                        if content_clean.lower().startswith(actor.lower()):
                            events.append(f"  - {stt}: {content_clean[0].upper() + content_clean[1:]}")
                        else:
                            events.append(f"  - {stt}: {actor.capitalize()} {content_clean[0].lower() + content_clean[1:] if len(content_clean) > 0 else ''}")
                    else:
                        events.append(f"  - {stt}: {content_clean}")
                        
            # Format lại chuỗi tác nhân cho phần nội dung (content)
            actors_content_str = ", ".join([a.capitalize() for a in actors])
            
            content_str = f"Tên quy trình: {process_name}\nTác nhân: {actors_content_str}\nĐiều kiện đầu vào: {precondition}\nLuồng sự kiện chính:\n"
            content_str += "\n".join(events)
            content_str += f"\nKết quả: {results}."
            
            # Trích xuất các từ khóa (tags)
            tags = [word.lower() for word in process_name.replace("Quy trình", "").split() if len(word) > 2]
            
            proc = {
                "id": f"process_{len(processes) + 1:03d}",
                "process_name": process_name,
                "module": module,
                "actors": actors,
                "precondition": precondition,
                "tags": tags,
                "content": content_str
            }
            processes.append(proc)
        except Exception as e:
            print(f"Lỗi khi xử lý bảng {i}: {e}")
            
    with open("data/rag_input_processes_auto.json", "w", encoding="utf-8") as f:
        json.dump(processes, f, ensure_ascii=False, indent=2)
        
    print(f"Hoàn tất. Đã bóc tách thành công {len(processes)} quy trình.")

if __name__ == "__main__":
    convert()
