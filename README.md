# Hệ thống Quản lý kho đồ khô, ngũ cốc

Dự án ứng dụng di động Flutter quản lý kho hàng (Phiên bản dành cho Admin). 
Được xây dựng theo mô hình MVC, sử dụng Material Design 3 và lưu trữ Mock Data bằng SharedPreferences.

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

---

## 🚀 Getting Started

This project is a starting point for a Flutter application.

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)
