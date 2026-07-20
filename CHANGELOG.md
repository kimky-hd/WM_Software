# CHANGELOG

Ghi lại các thay đổi đã thực hiện trong dự án. Phạm vi theo ma trận phân quyền trong [README.md](README.md).

## 2026-07-20

### Thêm mới — Đăng nhập thật + Module Quản lý kho

- **Đăng nhập** (`lib/screens/auth/login_screen.dart`, `lib/state/auth_store.dart`): thay màn "chọn role" mock bằng form email + mật khẩu thật, không có đăng ký. 3 tài khoản demo tạo sẵn trong `lib/data/mock_data.dart` (`admin@wm.local`, `manager@wm.local`, `staff@wm.local`).
- **Model dùng chung**: thêm trạng thái `cancelled` vào `enums.dart`, thêm `rejectReason` cho các loại phiếu còn thiếu, thêm `sourceNoteId` cho `Batch`, thêm `AuditLogEntry` (`lib/models/audit_log.dart`).
- **`lib/state/warehouse_store.dart`**: thêm duyệt/từ chối/huỷ cho cả 6 loại phiếu (tự tạo lô khi duyệt nhập, trừ/hoàn tồn khi xuất/trả NCC/hàng hỏng), CRUD nhà cung cấp, các getter cảnh báo tồn thấp/sắp hết hạn/hết hạn, Audit Log.
- **Màn hình Quản lý kho** (`lib/screens/manager/`): Dashboard tổng quan, Duyệt phiếu (6 loại), Danh mục (Nhà cung cấp CRUD, Sản phẩm xem + đề xuất sửa, Đơn vị tính xem), Báo cáo & Nhật ký (tồn theo lô, hao hụt/hỏng, audit log).
- Đã kiểm tra: `flutter analyze` sạch, chạy thật trên Chrome — đăng nhập cả 3 role, 4 tab Quản lý kho render đúng, không lỗi console.

## 2026-07-18

### Sửa lỗi

- **[lib/main.dart](lib/main.dart)** — sửa 2 lỗi cú pháp khiến app không build được:
  - `colorScheme: .fromSeed(...)` → `ColorScheme.fromSeed(...)`
  - `mainAxisAlignment: .center` → `MainAxisAlignment.center`
- Chạy `flutter pub get` lần đầu (project chưa từng tải dependencies — thiếu thư mục `.dart_tool` khiến analyzer báo lỗi "Undefined name" với cả các class có sẵn của Flutter như `Colors`).
- **[test/widget_test.dart](test/widget_test.dart)** — file test mặc định (đếm số counter) không còn phù hợp vì đã thay toàn bộ `main.dart`; viết lại thành 2 smoke test cho màn Đăng nhập và Trang chủ Nhân viên kho.

### Thêm mới — Module Nhân viên kho

**Dependencies** ([pubspec.yaml](pubspec.yaml)): `provider`, `shared_preferences`, `uuid`, `intl`.

**Model dữ liệu** (`lib/models/`): `enums.dart` (UserRole, DocumentStatus, DamageType), `user.dart`, `product.dart`, `unit.dart`, `supplier.dart`, `batch.dart`, `inbound_note.dart`, `outbound_note.dart`, `stock_check_note.dart`, `adjustment_note.dart`, `return_supplier_note.dart`, `damage_expired_note.dart`.

**Data layer** (`lib/data/`):
- `mock_data.dart` — dữ liệu mẫu (3 user theo 3 role, 4 đơn vị tính, 3 NCC, 5 sản phẩm, 6 lô hàng có cả lô sắp hết hạn/đã hết hạn để test).
- `app_storage.dart` — lớp bọc SharedPreferences, lưu/đọc danh sách dạng JSON (lưu trữ tạm thời theo đúng README).

**State management** (`lib/state/`):
- `auth_store.dart` — đăng nhập theo role (mock), lưu phiên qua SharedPreferences.
- `warehouse_store.dart` — store trung tâm: danh mục dùng chung + toàn bộ chứng từ; có logic gợi ý xuất kho theo **FEFO** (`suggestFefoAllocation`); mọi phiếu nhân viên tạo đều ở trạng thái **"Chờ duyệt"** (không tự trừ/cộng tồn kho — việc đó thuộc về bước Quản lý kho duyệt, ngoài phạm vi lần này).

**Màn hình** (`lib/screens/`):
- `auth/login_screen.dart` — chọn vai trò đăng nhập (chỉ Nhân viên kho hoạt động, Admin/Quản lý kho để "sắp ra mắt" cho nhóm làm sau).
- `staff/staff_home_screen.dart` — trang chủ dạng lưới 8 chức năng.
- `staff/inventory_view_screen.dart` — xem tồn kho theo sản phẩm + lô hàng (chỉ xem).
- `staff/inbound_note_list_screen.dart` + `inbound_note_form_screen.dart` — tạo phiếu nhập, gắn lô hàng mới (mã lô, ngày SX, HSD).
- `staff/outbound_note_list_screen.dart` + `outbound_note_form_screen.dart` — tạo phiếu xuất, gợi ý phân bổ theo FEFO, cho phép chỉnh lô thủ công.
- `staff/stock_check_list_screen.dart` + `stock_check_form_screen.dart` — kiểm kê, nhập số đếm thực tế so với tồn hệ thống.
- `staff/adjustment_note_screen.dart` — đề xuất điều chỉnh tồn kho (tăng/giảm + lý do).
- `staff/return_supplier_screen.dart` — phiếu trả hàng NCC.
- `staff/damage_expired_screen.dart` — phiếu hàng hỏng/hết hạn.
- `staff/qr_scan_screen.dart` — tra cứu nhanh theo mã SP/mã lô (**bản demo nhập/chọn mã thủ công, chưa gắn camera thật** — cần thêm package quét mã + cấu hình quyền camera nếu muốn dùng camera thực tế).

**Widget dùng chung** (`lib/widgets/`): `status_badge.dart`, `empty_state.dart`, `app_feedback.dart` (SnackBar thành công/lỗi theo UI guideline).

**[lib/main.dart](lib/main.dart)** — viết lại: wiring `MultiProvider` (AuthStore, WarehouseStore), theme Material 3 (seed `Colors.amber`, bo góc, theo UI guideline trong README), `AuthGate` điều hướng theo trạng thái đăng nhập/vai trò.

### Đã kiểm tra

- `flutter analyze` — không còn lỗi/cảnh báo.
- `flutter test` — 2/2 test pass.
- `flutter run -d windows` — build và chạy thành công, hiển thị đúng màn hình đăng nhập.

### Chưa làm (để nhóm làm tiếp)

- Camera quét mã QR/Barcode thật.
- Kết nối backend/API thật (hiện đang dùng SharedPreferences tạm thời theo đúng README).

---

### Ghi chú lịch sử (bản nháp trước đó của module Nhân viên kho, không còn được dùng)

> Bản dưới đây mô tả một bản nháp sớm hơn của module Nhân viên kho (đặt tên khác: `BatchModel`, `NoteStatus`, `StaffLayoutScreen`...), được commit thẳng lên `main` nhưng chưa từng nối vào `main.dart`. Đã refactor thành bản ở trên (tên gọn hơn, tích hợp Provider). Giữ lại các file này trong repo để tham khảo, không xoá.

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
