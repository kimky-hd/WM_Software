import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../state/auth_store.dart';
import '../../state/warehouse_store.dart';
import 'manager_approvals_screen.dart';
import 'manager_catalog_screen.dart';
import 'manager_dashboard_screen.dart';
import 'manager_reports_screen.dart';

/// Shell điều hướng cho role Quản lý kho: 4 tab chính theo ma trận phân quyền
/// (Tổng quan, Duyệt phiếu, Danh mục, Báo cáo & Nhật ký).
class ManagerHomeScreen extends StatefulWidget {
  const ManagerHomeScreen({super.key});

  @override
  State<ManagerHomeScreen> createState() => _ManagerHomeScreenState();
}

class _ManagerHomeScreenState extends State<ManagerHomeScreen> {
  int _index = 0;

  static const _titles = ['Tổng quan', 'Duyệt phiếu', 'Danh mục', 'Báo cáo & Nhật ký'];

  static const _screens = [
    ManagerDashboardScreen(),
    ManagerApprovalsScreen(),
    ManagerCatalogScreen(),
    ManagerReportsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthStore>().currentUser;
    final pendingCount = context.watch<WarehouseStore>().pendingApprovalCount;

    return Scaffold(
      appBar: AppBar(
        title: Text(_index == 0 ? 'Xin chào, ${user?.name ?? ''}' : _titles[_index]),
        actions: [
          IconButton(
            tooltip: 'Đăng xuất',
            icon: const Icon(Icons.logout),
            onPressed: () => context.read<AuthStore>().logout(),
          ),
        ],
      ),
      body: IndexedStack(index: _index, children: _screens),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: [
          const NavigationDestination(icon: Icon(Icons.dashboard_outlined), label: 'Tổng quan'),
          NavigationDestination(
            icon: Badge(
              isLabelVisible: pendingCount > 0,
              label: Text('$pendingCount'),
              child: const Icon(Icons.fact_check_outlined),
            ),
            label: 'Duyệt phiếu',
          ),
          const NavigationDestination(icon: Icon(Icons.category_outlined), label: 'Danh mục'),
          const NavigationDestination(icon: Icon(Icons.bar_chart_outlined), label: 'Báo cáo'),
        ],
      ),
    );
  }
}
