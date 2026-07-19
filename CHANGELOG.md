# Changelog

Tài liệu ghi lại các thay đổi chính của dự án theo thời gian.

## [Unreleased] - 2026-07-18

### Thêm mới — Chức năng Nhân viên kho

Xây dựng đầy đủ nghiệp vụ dành cho vai trò **Nhân viên kho** theo tài liệu thiết kế trong `README.md` (mục 2C, 3, 5). Tất cả phiếu do NV kho tạo dừng ở trạng thái `Chờ duyệt` — chưa cập nhật tồn kho thật, vì luồng duyệt phiếu (Quản lý kho) chưa thuộc phạm vi lần này.

**Model dữ liệu mới** (`lib/models/`)
- `BatchModel` — lô hàng (mã lô, ngày SX, HSD, số lượng nhập/còn lại)
- `NoteStatus` — trạng thái phiếu dùng chung (Nháp/Chờ duyệt/Đã duyệt/Hoàn thành/Từ chối)
- `InboundNoteModel`, `OutboundNoteModel`, `StockCheckNoteModel`, `AdjustmentNoteModel`, `ReturnSupplierNoteModel`, `DamageNoteModel` — 6 loại chứng từ kho

**Service layer**
- `WarehouseRepository` (`lib/services/warehouse_repository.dart`) — tầng dữ liệu dùng chung cho các màn NV kho: CRUD cho từng loại phiếu/lô hàng, tính tồn kho theo sản phẩm, gợi ý phân bổ lô theo nguyên tắc **FEFO** (hết hạn sớm nhất xuất trước), sinh mã phiếu tự động, và seed sẵn dữ liệu mẫu (5 sản phẩm, 2 nhà cung cấp, 6 lô hàng) để test ngay khi chưa có dữ liệu thật.

**Màn hình mới** (`lib/screens/staff/`)
- `StaffLayoutScreen` — khung điều hướng Drawer riêng cho NV kho
- `StaffDashboardScreen` — tổng quan số phiếu chờ duyệt, số mặt hàng, cảnh báo dưới mức tồn tối thiểu, lối tắt tạo phiếu
- `StockViewScreen` — xem tồn kho theo sản phẩm + truy vết chi tiết từng lô hàng
- 6 cặp màn **danh sách + tạo/sửa phiếu**: Phiếu nhập kho, Phiếu xuất kho (có gợi ý FEFO), Phiếu kiểm kê, Đề xuất điều chỉnh tồn, Phiếu trả hàng NCC, Phiếu hàng hỏng/hết hạn

**Widget dùng chung**
- `NoteStatusChip` (`lib/widgets/note_status_chip.dart`) — chip màu hiển thị trạng thái phiếu, dùng lại ở mọi màn danh sách

### Ghi chú
- Chưa đụng đến `main.dart`/routing — `StaffLayoutScreen` cần được nối vào entry point/luồng phân quyền khi làm màn Đăng nhập.
- Đã kiểm thử: `flutter analyze` sạch, build và chạy thật trên Windows desktop (`flutter run -d windows`) qua các luồng Tổng quan, Tồn kho, Drawer navigation.
