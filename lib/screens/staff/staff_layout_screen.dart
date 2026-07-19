import 'package:flutter/material.dart';
import '../../services/warehouse_repository.dart';
import 'adjustment_note_list_screen.dart';
import 'damage_note_list_screen.dart';
import 'inbound_note_list_screen.dart';
import 'outbound_note_list_screen.dart';
import 'return_supplier_note_list_screen.dart';
import 'staff_dashboard_screen.dart';
import 'stock_check_note_list_screen.dart';
import 'stock_view_screen.dart';

class StaffLayoutScreen extends StatefulWidget {
  const StaffLayoutScreen({super.key});

  @override
  State<StaffLayoutScreen> createState() => _StaffLayoutScreenState();
}

class _StaffLayoutScreenState extends State<StaffLayoutScreen> {
  int _selectedIndex = 0;
  String _appBarTitle = 'Tổng quan';
  bool _seeding = true;

  @override
  void initState() {
    super.initState();
    WarehouseRepository.instance.seedSampleDataIfEmpty().then((_) {
      if (mounted) setState(() => _seeding = false);
    });
  }

  void _onItemTapped(int index, String title) {
    setState(() {
      _selectedIndex = index;
      _appBarTitle = title;
    });
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    if (_seeding) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final screens = <Widget>[
      StaffDashboardScreen(onNavigate: (index, title) => setState(() {
        _selectedIndex = index;
        _appBarTitle = title;
      })),
      const StockViewScreen(),
      const InboundNoteListScreen(),
      const OutboundNoteListScreen(),
      const StockCheckNoteListScreen(),
      const AdjustmentNoteListScreen(),
      const ReturnSupplierNoteListScreen(),
      const DamageNoteListScreen(),
    ];

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
                    child: Icon(Icons.badge, size: 36, color: Colors.amber),
                  ),
                  SizedBox(height: 12),
                  Text(WarehouseRepository.currentStaffName,
                      style: TextStyle(color: Colors.black87, fontSize: 18, fontWeight: FontWeight.bold)),
                  Text('Nhân viên kho', style: TextStyle(color: Colors.black54, fontSize: 14)),
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
              leading: const Icon(Icons.inventory),
              title: const Text('Tồn kho'),
              selected: _selectedIndex == 1,
              onTap: () => _onItemTapped(1, 'Tồn kho'),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.call_received),
              title: const Text('Phiếu nhập kho'),
              selected: _selectedIndex == 2,
              onTap: () => _onItemTapped(2, 'Phiếu nhập kho'),
            ),
            ListTile(
              leading: const Icon(Icons.call_made),
              title: const Text('Phiếu xuất kho'),
              selected: _selectedIndex == 3,
              onTap: () => _onItemTapped(3, 'Phiếu xuất kho'),
            ),
            ListTile(
              leading: const Icon(Icons.fact_check),
              title: const Text('Phiếu kiểm kê'),
              selected: _selectedIndex == 4,
              onTap: () => _onItemTapped(4, 'Phiếu kiểm kê'),
            ),
            ListTile(
              leading: const Icon(Icons.tune),
              title: const Text('Đề xuất điều chỉnh tồn'),
              selected: _selectedIndex == 5,
              onTap: () => _onItemTapped(5, 'Đề xuất điều chỉnh tồn'),
            ),
            ListTile(
              leading: const Icon(Icons.assignment_return),
              title: const Text('Trả hàng NCC'),
              selected: _selectedIndex == 6,
              onTap: () => _onItemTapped(6, 'Phiếu trả hàng NCC'),
            ),
            ListTile(
              leading: const Icon(Icons.report_problem_outlined),
              title: const Text('Hàng hỏng/hết hạn'),
              selected: _selectedIndex == 7,
              onTap: () => _onItemTapped(7, 'Phiếu hàng hỏng/hết hạn'),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text('Đăng xuất', style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
      body: screens[_selectedIndex],
    );
  }
}
