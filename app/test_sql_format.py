from app.pipeline.chat_pipeline import generate_natural_answer

print("Testing Empty Data:")
res1 = generate_natural_answer("doanh thu tháng 4", "[]")
print(res1)
print("\n" + "="*50 + "\n")

print("Testing Valid Data:")
res2 = generate_natural_answer("doanh thu tháng 4", '[{"doanhThuThang4": 15000000}]')
print(res2)
