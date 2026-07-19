# 🌾 Hệ thống Quản lý kho đồ khô, ngũ cốc

Dự án ứng dụng di động Flutter quản lý kho hàng. Phiên bản 1.0 (Tháng 7, 2026).
Mô hình 1 kho duy nhất — 3 vai trò người dùng.

Được xây dựng theo mô hình MVC, sử dụng Material Design 3 và lưu trữ dữ liệu (tạm thời) bằng SharedPreferences.

---

## 📑 TÀI LIỆU THIẾT KẾ HỆ THỐNG

### 1. Phân quyền (Role)
Hệ thống áp dụng cho mô hình 1 kho duy nhất, gồm 3 vai trò người dùng theo cấp bậc:
- **Admin**: Quản trị hệ thống, không tham gia vận hành hàng ngày.
- **Quản lý kho**: Điều hành toàn bộ hoạt động kho, duyệt chứng từ.
- **Nhân viên kho**: Thao tác nghiệp vụ (nhập/xuất/kiểm kê thực tế).

### 2. Danh sách module chi tiết

#### A. Quản trị hệ thống
| Chức năng | Mô tả |
| :--- | :--- |
| **Đăng nhập / Đăng xuất** | Xác thực người dùng, phân quyền theo role |
| **Quản lý tài khoản** | Admin tạo tài khoản cho Quản lý kho, Nhân viên kho; khoá/mở tài khoản |
| **Đổi/Quên mật khẩu** | Áp dụng cho tất cả role |

#### B. Danh mục dùng chung
| Chức năng | Mô tả |
| :--- | :--- |
| **Danh mục sản phẩm** | Tên, mã SP, nhóm hàng (ngũ cốc/hạt/đồ khô...), đơn vị tính cơ bản, HSD mặc định, mức tồn tối thiểu |
| **Đơn vị tính & quy đổi** | VD: 1 bao = 25kg, 1 tấn = 1000kg — dùng khi nhập theo bao, xuất theo kg |
| **Nhà cung cấp** | Tên, liên hệ, mã số thuế, lịch sử giao dịch |
| **Vị trí lưu trữ (tuỳ chọn)** | Khu A - Kệ 3 - Tầng 2, giúp tìm hàng nhanh |

#### C. Nghiệp vụ kho — Chứng từ
| Chứng từ | Người tạo | Người duyệt | Ghi chú |
| :--- | :--- | :--- | :--- |
| **Phiếu nhập kho** | Nhân viên kho | Quản lý kho | Gắn lô hàng (ngày SX, HSD) khi nhập |
| **Phiếu xuất kho** | Nhân viên kho | Quản lý kho | Ưu tiên xuất lô hết hạn sớm (FEFO) |
| **Phiếu kiểm kê** | Nhân viên kho | Quản lý kho | So sánh tồn hệ thống với tồn thực tế |
| **Phiếu điều chỉnh tồn** | Nhân viên kho (đề xuất)| Quản lý kho | Ghi rõ lý do: hao hụt, sai lệch kiểm kê... |
| **Phiếu trả hàng NCC** | Nhân viên kho | Quản lý kho | Hàng lỗi/không đạt chất lượng khi nhập |
| **Phiếu hàng hỏng/hết hạn** | Nhân viên kho | Quản lý kho | Xuất khỏi tồn kho, không tính là bán ra |

> **Trạng thái chứng từ:** `Nháp` → `Chờ duyệt` → `Đã duyệt (cập nhật tồn kho)` → `Hoàn thành`. Hoặc `Từ chối (trả về Nháp, kèm lý do)`.
> *Ghi chú:* Sau khi phiếu ở trạng thái Đã duyệt, Nhân viên kho không được sửa/xoá — chỉ Quản lý kho có quyền huỷ (có ghi log).

#### D. Quản lý lô hàng (Batch/Lot)
Đặc biệt quan trọng với ngành hàng đồ khô, ngũ cốc vì có hạn sử dụng và dễ hao hụt theo thời gian.
- **Gắn lô khi nhập:** mỗi phiếu nhập tạo 1 lô mới (mã lô, ngày SX, HSD, số lượng).
- **Xuất theo FEFO:** hệ thống tự gợi ý xuất lô có hạn sử dụng gần nhất trước.
- **Truy vết lô:** xem 1 lô đã nhập khi nào, xuất bao nhiêu, còn lại bao nhiêu.

#### E. Cảnh báo & Thông báo
| Loại cảnh báo | Điều kiện | Nhận thông báo |
| :--- | :--- | :--- |
| **Tồn kho thấp** | Số lượng < mức tồn tối thiểu | Admin + Quản lý kho |
| **Sắp hết hạn** | HSD lô hàng còn ≤ X ngày | Admin + Quản lý kho |
| **Hết hạn** | HSD đã qua nhưng chưa xử lý | Admin + Quản lý kho |

#### F. Báo cáo & Dashboard
- **Dashboard tổng quan:** Tổng SP, tổng tồn kho, số phiếu chờ duyệt, cảnh báo hiện có.
- **Báo cáo nhập – xuất – tồn:** Theo khoảng thời gian, theo sản phẩm.
- **Báo cáo tồn kho theo lô:** Từng lô còn bao nhiêu, HSD còn bao lâu.
- **Báo cáo hao hụt/hàng hỏng:** Tổng hợp theo kỳ, theo nguyên nhân.
- **Xuất báo cáo:** Excel/PDF.

#### G. Kiểm soát
- **Nhật ký hoạt động (Audit Log):** Ghi nhận ai tạo/sửa/duyệt/xoá gì, thời điểm nào.
- **Khoá dữ liệu sau duyệt:** Đảm bảo tính toàn vẹn số liệu.

### 3. Ma trận phân quyền chi tiết

| Chức năng | Admin | Quản lý kho | Nhân viên kho |
| :--- | :--- | :--- | :--- |
| Quản lý tài khoản | ✓ | – | – |
| Danh mục sản phẩm | ✓ Toàn quyền | Xem, đề xuất sửa | Xem |
| Đơn vị tính & quy đổi | ✓ | Xem | Xem |
| Nhà cung cấp | ✓ | Thêm/sửa | Xem |
| Tạo phiếu nhập/xuất | – | Tạo + Duyệt | Tạo |
| Duyệt phiếu nhập/xuất | – | ✓ | – |
| Kiểm kê | Xem báo cáo | Duyệt kết quả | Thực hiện kiểm đếm |
| Điều chỉnh tồn kho | Xem | Duyệt | Đề xuất |
| Phiếu trả NCC / hàng hỏng | Xem | Duyệt | Tạo |
| Xem tồn kho | ✓ | ✓ | ✓ (chỉ xem) |
| Quét mã QR/Barcode | – | ✓ | ✓ |
| Nhận cảnh báo tồn/HSD | ✓ | ✓ | – |
| Báo cáo & Dashboard | ✓ Toàn bộ | ✓ (kho của mình) | – |
| Audit Log | ✓ | Xem log của kho | – |
| Sửa dữ liệu đã duyệt | – | Huỷ phiếu (có log) | – |

### 4. Thiết kế dữ liệu chính (Data Models)
- `User` (id, họ tên, email, role, trạng thái)
- `Product` (id, mã SP, tên, nhóm hàng, đơn vị tính, mức tồn tối thiểu, HSD mặc định)
- `Unit` (id, tên đơn vị, hệ số quy đổi về đơn vị gốc)
- `Supplier` (id, tên, liên hệ, mã số thuế)
- `Batch/Lot` (id, product_id, mã lô, ngày SX, HSD, số lượng nhập, số lượng còn lại)
- `InboundNote` (id, mã phiếu, ngày tạo, người tạo, người duyệt, trạng thái, supplier_id)
- `InboundNoteDetail` (note_id, batch_id, số lượng, đơn vị)
- `OutboundNote` (id, mã phiếu, ngày tạo, người tạo, người duyệt, trạng thái, mục đích)
- `OutboundNoteDetail` (note_id, batch_id, số lượng, đơn vị)
- `StockCheckNote` (id, ngày kiểm, người thực hiện, người duyệt, trạng thái)
- `StockCheckDetail` (note_id, product_id, tồn hệ thống, tồn thực tế, chênh lệch)
- `AdjustmentNote` (id, product_id/batch_id, số lượng điều chỉnh, lý do, người duyệt)
- `ReturnToSupplierNote` (id, supplier_id, batch_id, số lượng, lý do)
- `DamageExpiredNote` (id, batch_id, số lượng, loại, lý do)
- `Notification` (id, loại, nội dung, đối tượng nhận, đã đọc?)
- `AuditLog` (id, user_id, hành động, đối tượng, thời gian, dữ liệu trước/sau)

### 5. Luồng nghiệp vụ mẫu

**5.1. Phiếu nhập kho**
1. Nhân viên kho tạo phiếu nhập → chọn NCC, sản phẩm, số lượng, ngày SX/HSD → trạng thái: "Chờ duyệt".
2. Quản lý kho xem xét:
   - Duyệt: hệ thống tạo Batch mới, cộng vào tồn kho.
   - Từ chối: trả về Nhân viên kho kèm lý do.
3. Sau khi duyệt: Sinh Audit Log. Nếu tồn vượt mức tối đa hoặc có bất thường → thông báo Admin.

**5.2. Phiếu xuất kho (nguyên tắc FEFO)**
1. Nhân viên kho tạo phiếu xuất → nhập sản phẩm + số lượng cần xuất.
2. Hệ thống tự gợi ý lô có HSD gần nhất, đủ số lượng → Nhân viên kho có thể điều chỉnh lô nếu cần (ghi log lý do).
3. Quản lý kho duyệt → Trừ tồn kho theo lô đã chọn. Nếu tồn kho sau xuất < mức tối thiểu → tạo cảnh báo.

---

## 🎨 UI/UX DESIGN GUIDELINES (PROMPT ĐỒNG BỘ GIAO DIỆN)

> **Mục đích:** Đoạn nội dung dưới đây đóng vai trò là "System Prompt" (Hệ quy chiếu). Bất kỳ developer hoặc AI Assistant nào khi làm việc ở các nhánh (branch) khác nhau đều phải tuân thủ nghiêm ngặt các quy tắc này để đảm bảo giao diện toàn hệ thống luôn đồng bộ.

### [UI FRAMEWORK PROMPT]
Khi code hoặc thiết kế bất kỳ màn hình (Screen) hoặc Component nào cho dự án này, hãy tuân thủ bộ quy tắc sau:

**1. Design System & Theme:**
- **Framework:** Bắt buộc sử dụng `Material Design 3` (`useMaterial3: true` trong `ThemeData`).
- **Màu sắc chủ đạo (Color Palette):**
  - Seed Color (Màu hạt giống): `Colors.amber` hoặc `Colors.orange` (Đại diện cho ngũ cốc, nông sản, đồ khô).
  - Màu nền (Background): Màu sáng nhẹ (Off-white) hoặc xám nhạt để làm nổi bật các thẻ Card màu trắng.
- **Typography:** Sử dụng Font chữ mặc định của Material (Roboto) hoặc tích hợp Google Fonts (ví dụ `Inter` hoặc `Nunito`). Cấu trúc: Title lớn, rõ ràng.

**2. Layout & Navigation (Admin Role):**
- Bắt buộc sử dụng **Drawer Navigation** (Menu trượt ngang bên trái) làm công cụ điều hướng chính thay vì BottomNavigationBar. Các mục trong Drawer: *Tổng quan (Dashboard), Sản phẩm, Nhà cung cấp, Tài khoản, Nhật ký (Audit Log)*.
- **AppBar:** Thiết kế tối giản, luôn có Tiêu đề trang (Title) ở giữa hoặc canh trái, chữ đậm vừa phải. Tích hợp nút chuông thông báo nếu cần.

**3. UI Components (Thành phần giao diện):**
- **Danh sách (List/Grid):** Sử dụng `Card` có bo góc (`borderRadius: BorderRadius.circular(12)` hoặc 16) và đổ bóng nhẹ (Elevation thấp) để hiển thị từng item (sản phẩm, user). Dùng `ListTile` bên trong Card để chuẩn hóa layout.
- **Thêm mới (Create):** Sử dụng `FloatingActionButton` (FAB) nằm ở góc dưới bên phải hoặc nằm ở góc trên AppBar để thêm mới dữ liệu.
- **Forms & Inputs:** Sử dụng `TextFormField` với `OutlineInputBorder` (viền bo tròn), luôn có `labelText` và `prefixIcon` minh họa rõ ràng.
- **Phản hồi người dùng (Feedback):**
  - **Loading:** Bắt buộc hiển thị `CircularProgressIndicator` ở giữa màn hình hoặc thay thế bằng hiệu ứng Skeleton/Shimmer khi đang tải dữ liệu.
  - **Thông báo thao tác:** Sau khi Thêm/Sửa/Xóa thành công hoặc thất bại, bắt buộc hiển thị `SnackBar` (Floating style, bo góc, màu xanh lá cho Success, đỏ cho Error).

**4. Khoảng cách (Spacing & Padding):**
- Standard Padding (lề màn hình): `16.0`.
- Khoảng cách giữa các phần tử dọc (Vertical): `SizedBox(height: 16.0)` hoặc `8.0`.
- Khoảng cách ngang (Horizontal): `SizedBox(width: 8.0)` hoặc `16.0`.

*(End of Prompt)*
