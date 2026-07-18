import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'data/app_storage.dart';
import 'models/enums.dart';
import 'screens/auth/login_screen.dart';
import 'screens/staff/staff_home_screen.dart';
import 'state/auth_store.dart';
import 'state/warehouse_store.dart';

void main() {
  runApp(const WmApp());
}

class WmApp extends StatelessWidget {
  const WmApp({super.key});

  @override
  Widget build(BuildContext context) {
    final storage = AppStorage();
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthStore(storage)..restoreSession()),
        ChangeNotifierProvider(create: (_) => WarehouseStore(storage)..init()),
      ],
      child: MaterialApp(
        title: 'Quản lý kho đồ khô, ngũ cốc',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.amber),
          scaffoldBackgroundColor: const Color(0xFFFAF9F6),
          cardTheme: const CardThemeData(
            elevation: 1,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(16))),
            margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          ),
          inputDecorationTheme: const InputDecorationTheme(
            border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
          ),
          appBarTheme: const AppBarTheme(centerTitle: false, elevation: 0),
        ),
        home: const AuthGate(),
      ),
    );
  }
}

/// Điều hướng theo trạng thái đăng nhập & vai trò người dùng.
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthStore>();

    if (auth.isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (!auth.isLoggedIn) {
      return const LoginScreen();
    }

    switch (auth.currentUser!.role) {
      case UserRole.warehouseStaff:
        return const StaffHomeScreen();
      case UserRole.admin:
      case UserRole.warehouseManager:
        return _RoleNotReadyScreen(role: auth.currentUser!.role);
    }
  }
}

class _RoleNotReadyScreen extends StatelessWidget {
  const _RoleNotReadyScreen({required this.role});

  final UserRole role;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(role.label)),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.construction_outlined, size: 48, color: Colors.grey),
              const SizedBox(height: 16),
              Text(
                'Chức năng cho "${role.label}" đang được phát triển ở nhánh khác.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 24),
              OutlinedButton.icon(
                onPressed: () => context.read<AuthStore>().logout(),
                icon: const Icon(Icons.logout),
                label: const Text('Đăng xuất'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
