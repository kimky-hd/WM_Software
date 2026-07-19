import 'package:flutter/material.dart';
import 'dashboard_screen.dart';
import 'supplier_management_screen.dart';
import 'product_management_screen.dart';
import 'user_management_screen.dart';

class AdminLayoutScreen extends StatefulWidget {
  const AdminLayoutScreen({super.key});

  @override
  State<AdminLayoutScreen> createState() => _AdminLayoutScreenState();
}

class _AdminLayoutScreenState extends State<AdminLayoutScreen> {
  int _selectedIndex = 0;
  String _appBarTitle = 'Tổng quan';

  void _changeTab(int index) {
    String title = 'Tổng quan';
    switch (index) {
      case 1: title = 'Quản lý Sản phẩm'; break;
      case 2: title = 'Nhà cung cấp'; break;
      case 3: title = 'Quản lý Tài khoản'; break;
      case 4: title = 'Nhật ký (Audit Log)'; break;
    }
    setState(() {
      _selectedIndex = index;
      _appBarTitle = title;
    });
  }

  // Danh sách các màn hình được điều hướng
  List<Widget> get _screens => [
    DashboardScreen(onNavigate: _changeTab),
    const ProductManagementScreen(),
    const SupplierManagementScreen(),
    const UserManagementScreen(),
    const Center(child: Text('Nhật ký (Audit Log)')), // Sẽ code sau
  ];

  void _onItemTapped(int index, String title) {
    setState(() {
      _selectedIndex = index;
      _appBarTitle = title;
    });
    Navigator.pop(context); // Đóng Drawer sau khi chọn
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_appBarTitle, style: const TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none),
            onPressed: () {},
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(color: Colors.amber),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  CircleAvatar(
                    backgroundColor: Colors.white,
                    radius: 30,
                    child: Icon(Icons.admin_panel_settings, size: 40, color: Colors.amber),
                  ),
                  SizedBox(height: 12),
                  Text('Quản trị viên', style: TextStyle(color: Colors.black87, fontSize: 18, fontWeight: FontWeight.bold)),
                  Text('admin@warehouse.com', style: TextStyle(color: Colors.black54, fontSize: 14)),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.dashboard),
              title: const Text('Tổng quan'),
              selected: _selectedIndex == 0,
              onTap: () => _onItemTapped(0, 'Tổng quan'),
            ),
            ListTile(
              leading: const Icon(Icons.inventory_2),
              title: const Text('Sản phẩm'),
              selected: _selectedIndex == 1,
              onTap: () => _onItemTapped(1, 'Quản lý Sản phẩm'),
            ),
            ListTile(
              leading: const Icon(Icons.local_shipping),
              title: const Text('Nhà cung cấp'),
              selected: _selectedIndex == 2,
              onTap: () => _onItemTapped(2, 'Nhà cung cấp'),
            ),
            ListTile(
              leading: const Icon(Icons.manage_accounts),
              title: const Text('Tài khoản User'),
              selected: _selectedIndex == 3,
              onTap: () => _onItemTapped(3, 'Quản lý Tài khoản'),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.history),
              title: const Text('Nhật ký hệ thống'),
              selected: _selectedIndex == 4,
              onTap: () => _onItemTapped(4, 'Nhật ký (Audit Log)'),
            ),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text('Đăng xuất', style: TextStyle(color: Colors.red)),
              onTap: () {
                // Logic đăng xuất sẽ thêm sau
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
      body: _screens[_selectedIndex],
    );
  }
}
