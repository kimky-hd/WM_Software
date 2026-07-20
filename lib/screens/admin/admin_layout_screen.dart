import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../state/auth_store.dart';
import 'dashboard_screen.dart';
import 'supplier_management_screen.dart';
import 'product_management_screen.dart';
import 'user_management_screen.dart';
import 'audit_log_screen.dart';

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
    const AuditLogScreen(),
  ];

  void _onItemTapped(int index, String title) {
    setState(() {
      _selectedIndex = index;
      _appBarTitle = title;
    });
    Navigator.pop(context); // Đóng Drawer sau khi chọn
  }

  Widget _buildDrawerItem(IconData icon, String drawerTitle, String appBarTitle, int index) {
    return ListTile(
      leading: Icon(icon),
      title: Text(drawerTitle),
      selected: _selectedIndex == index,
      selectedTileColor: Colors.amber.withOpacity(0.2), // Highlight màu nền
      selectedColor: Colors.amber[900], // Highlight màu chữ/icon
      onTap: () => _onItemTapped(index, appBarTitle),
    );
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
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Tính năng thông báo đang phát triển')));
            },
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
            _buildDrawerItem(Icons.dashboard, 'Tổng quan', 'Tổng quan', 0),
            _buildDrawerItem(Icons.inventory_2, 'Sản phẩm', 'Quản lý Sản phẩm', 1),
            _buildDrawerItem(Icons.local_shipping, 'Nhà cung cấp', 'Nhà cung cấp', 2),
            _buildDrawerItem(Icons.manage_accounts, 'Tài khoản User', 'Quản lý Tài khoản', 3),
            const Divider(),
            _buildDrawerItem(Icons.history, 'Nhật ký hệ thống', 'Nhật ký (Audit Log)', 4),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text('Đăng xuất', style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(context); // Đóng drawer
                showDialog(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    backgroundColor: Colors.white,
                    title: const Text('Xác nhận đăng xuất'),
                    content: const Text('Bạn có chắc chắn muốn đăng xuất không?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: const Text('Không', style: TextStyle(color: Colors.grey)),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.pop(ctx);
                          context.read<AuthStore>().logout();
                        },
                        child: const Text('Có', style: TextStyle(color: Colors.red)),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
      body: _screens[_selectedIndex],
    );
  }
}
