// Basic smoke test: ứng dụng khởi động và hiển thị màn hình đăng nhập với
// đủ 3 lựa chọn vai trò.

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:wm_software/main.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('Hiển thị màn hình đăng nhập với các vai trò', (WidgetTester tester) async {
    await tester.pumpWidget(const WmApp());
    // Không dùng pumpAndSettle: CircularProgressIndicator lúc loading là
    // animation vô hạn nên sẽ không bao giờ "settle".
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Nhân viên kho'), findsOneWidget);
    expect(find.text('Quản lý kho'), findsOneWidget);
    expect(find.text('Admin'), findsOneWidget);
  });

  testWidgets('Đăng nhập Nhân viên kho vào được trang chủ', (WidgetTester tester) async {
    await tester.pumpWidget(const WmApp());
    // Không dùng pumpAndSettle: CircularProgressIndicator lúc loading là
    // animation vô hạn nên sẽ không bao giờ "settle".
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    await tester.tap(find.text('Nhân viên kho'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Tồn kho'), findsOneWidget);
    expect(find.text('Phiếu nhập kho'), findsOneWidget);
  });
}
