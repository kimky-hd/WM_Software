import 'package:flutter/material.dart';
import 'screens/admin_layout_screen.dart';
import 'services/shared_prefs_service.dart';

void main() async {
  // Đảm bảo Flutter binding được khởi tạo trước khi gọi SharedPreferences
  WidgetsFlutterBinding.ensureInitialized();
  
  // Khởi tạo dịch vụ SharedPreferences dùng chung
  await SharedPrefsService.instance.init();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Quản lý kho',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.amber),
        useMaterial3: true,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.amber,
          foregroundColor: Colors.black87,
        ),
      ),
      // Tạm thời bỏ qua màn hình Login, cho Admin vào thẳng hệ thống để dễ code UI
      home: const AdminLayoutScreen(),
    );
  }
}
