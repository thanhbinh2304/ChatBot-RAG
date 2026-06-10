import re
from typing import List
# pyrefly: ignore [missing-import]
from rank_bm25 import BM25Okapi

FULL_SCHEMA = """-- BẢNG DỮ LIỆU CỦA HỆ THỐNG GAS TUẤN ĐẠT --
Account(accountId [PK], username, password, status, createdAt, updatedAt, roleId [FK -> Role.roleId], deleteAt, employeeId [FK -> Employee.employeeId]) -- Tài khoản người dùng
Area(areaId [PK], areaName) -- Khu vực
CashReceipt(receiptId [PK], receiptDate, receiptAmount, note, customerId [FK -> Customer.customerId], createdBy [FK -> Employee.employeeId], transactionTypeId [FK -> TransactionType.transactionTypeId], invoiceId [FK -> SaleInvoice.invoiceId], PaymentMethod [ENUM: 'Cashes', 'QR_Code'], objectId [FK -> Object.objectId], supplierId [FK -> Supplier.supplierId], receiptCode, createdDate, employeeId) -- Phiếu thu tiền (Tiền vào)
Customer(customerId [PK], gender, dateOfBirth, note, fullName, phoneNumber, email, wardId [FK -> Ward.wardId], customerGroupId [FK -> CustomerGroup.customerGroupid], customerCode, address, debt) -- Khách hàng
CustomerGroup(customerGroupId, groupName) -- Loại khách hàng
Employee(employeeId [PK], employeeCode, positionId [FK -> Position.positionId], note, status, hireDate, createdAt, updatedAt, gender, dateOfBirth, phoneNumber, fullName, email, wardId) -- Nhân viên
GasBook(gasBookId [PK], gender, dateOfBirth, points, cycles, note, fullName, phoneNumber, email, wardId [FK -> Ward.wardId], cycle, customerGroupid [FK -> CustomerGroup.customerGroupid], address, debt, gasBookCode) -- Sổ Gas của khách hàng
Inventory(stockId [FK -> Stock.stockId], productId [FK -> Product.productId], quantity, inventoryId [PK]) -- Tồn kho hàng hóa
InvoiceDetail(id, quantity, total, unitPrice, invoiceId, productId) -- Chi tiết các mặt hàng trong Hóa đơn bán (SaleInvoice)
Object(objectId [PK], objectCode, objectName, objectType [ENUM: 'Nhanvien', 'Nhacungcap', 'Khachhang', 'Sogas'], wardId [FK -> Ward.wardId]) -- Đối tượng thu chi
Payment(paymentId [PK], paymentDate, paymentAmount, notes, objectId [FK -> Object.objectId], createdBy [FK -> Employee.employeeId], transactionTypeId [FK -> TransactionType.transactionTypeId], purchaseId [FK -> PurchaseOrder.purchaseId], stockId [FK -> Stock.stockId], paymentMethod [ENUM: 'Cashes', 'QR_Code'], supplierId [FK -> Supplier.supplierId], customerId [FK -> Customer.customerId], employeeId, paymentCode) -- Phiếu chi tiền (Tiền ra)
Position(positionId [PK], name) -- Chức vụ nhân viên
PriceList(priceListId [PK], priceListName) -- Bảng giá
Product(productId [PK], productName, unit, cost, categoryId [FK -> ProductCategory.categoryId], note, productCode) -- Thông tin sản phẩm / hàng hóa
ProductCategory(categoryId [PK], categoryName) -- Danh mục sản phẩm
PurchaseDetail(purchaseId [FK -> PurchaseOrder.purchaseId], productId [FK -> Product.productId], quantity, purchasePrice, total, id) -- Chi tiết các mặt hàng trong phiếu nhập
PurchaseOrder(purchaseId [PK], purchaseDate, totalAmount, employeeId [FK -> Employee.employeeId], supplierId [FK -> Supplier.supplierId], note, orderType [ENUM: 'Dathang' (Đặt), 'Xuathang' (Bán/Doanh thu), 'Nhaphang' (Nhập)], stockId [FK -> Stock.stockId], discountAmount, paidAmount, purchaseCode) -- Phiếu nhập hàng / Mua hàng từ nhà cung cấp
SaleInvoice(invoiceId [PK], invoiceDate, totalAmount, discountAmount, paidAmount, note, employeeId [FK -> Employee.employeeId], customerId [FK -> Customer.customerId], gasBookId [FK -> GasBook.gasBookId], stockId [FK -> Stock.stockId], orderType [ENUM: 'Dathang' (Đặt), 'Xuathang' (Bán/Doanh thu), 'Nhaphang' (Nhập)], invoiceCode, PaymentMethod [ENUM: 'Cashes', 'QR_Code']) -- Hóa đơn bán hàng / Doanh thu bán hàng
Stock(name, wardId [FK -> Ward.wardId], stockId [PK]) -- Cửa hàng / Kho chứa
StockTake(stockTakeId [PK], stockTakeDate, note, employeeId [FK -> Employee.employeeId], stockId [FK -> Stock.stockId], stockTakeCode) -- Phiếu kiểm kho
StockTakeDetail(stockTakeId [FK -> StockTake.stockTakeId], productId [FK -> Product.productId], systymQuantity, actualQuantity, id) -- Chi tiết kiểm kho
StockTransfer(transferId [PK], transferDate, fromStockId [FK -> Stock.stockId], toStockId [FK -> Stock.stockId], employeeId [FK -> Employee.employeeId], note, transferCode) -- Phiếu chuyển kho
StockTransferDetail(transferId [FK -> StockTransfer.transferId], productId [FK -> Product.productId], quantity, id) -- Chi tiết chuyển kho
Supplier(supplierId [PK], taxNumber, note, fullName, phoneNumber, email, wardId [FK -> Ward.wardId], createdAt, updatedAt, address, debt) -- Nhà cung cấp
Ward(wardId, wardName, areaId) -- Phường/Xã"""

class SchemaPruner:
    def __init__(self, schema_text: str = FULL_SCHEMA):
        self.tables = []
        self.tokenized_corpus = []
        
        # Parse schema into lines
        lines = schema_text.strip().split("\n")
        self.header = lines[0] if lines and lines[0].startswith("--") else ""
        
        for line in lines:
            if line.startswith("-- BẢNG DỮ LIỆU") or not line.strip():
                continue
            self.tables.append(line.strip())
            
            # Tokenize cho BM25: lowercase, bỏ dấu câu, giữ lại chữ và số
            tokens = re.findall(r'\w+', line.lower())
            self.tokenized_corpus.append(tokens)
            
        self.bm25 = BM25Okapi(self.tokenized_corpus)
        
    def prune(self, query: str, top_k: int = 5) -> str:
        """
        Lấy ra top_k bảng liên quan nhất đến query.
        """
        query_tokens = re.findall(r'\w+', query.lower())
        
        # Nếu query không có từ nào hợp lệ (hiếm gặp), trả về 5 bảng đầu
        if not query_tokens:
            pruned = [self.header] + self.tables[:top_k]
            return "\n".join(pruned)
        
        # Lấy điểm của các bảng
        scores = self.bm25.get_scores(query_tokens)
        
        # Lấy top_k index có điểm cao nhất
        top_indices = sorted(range(len(scores)), key=lambda i: scores[i], reverse=True)[:top_k]
        
        # Bọc kết quả
        pruned_schema = [self.header] if self.header else []
        for idx in top_indices:
            # Chỉ lấy các bảng có điểm > 0 hoặc lấy đủ số lượng cũng được,
            # ở đây ta sẽ lấy luôn top_k bảng liên quan nhất để đảm bảo có schema.
            pruned_schema.append(self.tables[idx])
            
        return "\n".join(pruned_schema)

# Khởi tạo một instance mặc định (Singleton-like) để tái sử dụng BM25 index
_default_pruner = SchemaPruner()

def get_pruned_schema(query: str, top_k: int = 5) -> str:
    """
    Hàm tiện ích để lọc schema dựa trên câu hỏi người dùng.
    Mặc định lấy 5 bảng liên quan nhất.
    """
    return _default_pruner.prune(query, top_k)
