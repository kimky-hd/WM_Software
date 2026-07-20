import 'package:flutter/material.dart';
import '../../models/product_model.dart';
import '../../models/supplier_model.dart';
import '../../models/user_model.dart';
import '../../services/shared_prefs_service.dart';

class DashboardScreen extends StatefulWidget {
  final Function(int)? onNavigate;
  const DashboardScreen({super.key, this.onNavigate});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  bool _isLoading = true;
  int _totalProducts = 0;
  int _totalSuppliers = 0;
  int _totalUsers = 0;
  int _lowStockAlerts = 0;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    setState(() => _isLoading = true);
    
    // Giả lập độ trễ UX
    await Future.delayed(const Duration(milliseconds: 400));
    
    final products = SharedPrefsService.instance.getDataList('products', ProductModel.fromJson);
    final suppliers = SharedPrefsService.instance.getDataList('suppliers', SupplierModel.fromJson);
    final users = SharedPrefsService.instance.getDataList('users', UserModel.fromJson);
    
    // Đếm số sản phẩm có tồn kho tối thiểu > 0 (Tạm thời coi như tồn kho = 0 vì chưa có tính năng Nhập kho)
    int lowStock = 0;
    for (var p in products) {
      if (p.minStockLevel > 0) lowStock++;
    }

    setState(() {
      _totalProducts = products.length;
      _totalSuppliers = suppliers.length;
      _totalUsers = users.length;
      _lowStockAlerts = lowStock;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: Colors.amber));
    }

    return RefreshIndicator(
      color: Colors.amber,
      onRefresh: _loadDashboardData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Số liệu Tổng quan',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
            ),
            const SizedBox(height: 16),
            GridView.count(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              childAspectRatio: 1.5,
              children: [
                _buildStatCard('Sản phẩm', _totalProducts.toString(), Icons.inventory_2, Colors.blue, onTap: () => widget.onNavigate?.call(1)),
                _buildStatCard('Đối tác', _totalSuppliers.toString(), Icons.local_shipping, Colors.green, onTap: () => widget.onNavigate?.call(2)),
                _buildStatCard('Tài khoản', _totalUsers.toString(), Icons.manage_accounts, Colors.purple, onTap: () => widget.onNavigate?.call(3)),
                _buildStatCard('Cảnh báo', _lowStockAlerts.toString(), Icons.warning_amber, Colors.orange, onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Tính năng cảnh báo đang phát triển')));
                }),
              ],
            ),
            
            const SizedBox(height: 32),
            
            const Text(
              'Truy cập nhanh',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildQuickAction(Icons.add_box, 'Nhập hàng', Colors.teal, onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Tính năng dành riêng cho Nhân viên kho')));
                }),
                _buildQuickAction(Icons.outbox, 'Xuất hàng', Colors.redAccent, onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Tính năng dành riêng cho Nhân viên kho')));
                }),
                _buildQuickAction(Icons.category, 'Mặt hàng', Colors.blue, onTap: () {
                  widget.onNavigate?.call(1); // Link sang tab số 1 (Sản phẩm)
                }),
                _buildQuickAction(Icons.qr_code_scanner, 'Quét mã', Colors.indigo, onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Chức năng quét mã vạch đang phát triển')));
                }),
              ],
            ),
            
            const SizedBox(height: 32),
            
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Hoạt động gần đây',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
                ),
                TextButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Tính năng xem toàn bộ nhật ký đang phát triển')));
                  },
                  child: const Text('Xem tất cả', style: TextStyle(color: Colors.amber, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            const SizedBox(height: 8),
            _buildActivityList(),
            
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color, {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, color: color, size: 28),
              Text(
                value,
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black87),
              ),
            ],
          ),
          const Spacer(),
          Text(
            title,
            style: const TextStyle(fontSize: 14, color: Colors.black54, fontWeight: FontWeight.w500),
          ),
        ],
      ),
      ),
    );
  }

  Widget _buildQuickAction(IconData icon, String label, Color color, {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 26),
          ),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Colors.black87)),
        ],
      ),
    );
  }

  Widget _buildActivityList() {
    // Dữ liệu giả lập cho Nhật ký hệ thống vì Admin chưa làm phiếu thực tế
    final activities = [
      {'title': 'Tài khoản admin_01 vừa đăng nhập', 'time': 'Hôm nay, 08:30', 'icon': Icons.login, 'color': Colors.purple},
      {'title': 'Hệ thống khởi tạo thành công', 'time': 'Hôm nay, 08:00', 'icon': Icons.check_circle, 'color': Colors.green},
    ];

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: activities.length,
      itemBuilder: (context, index) {
        final item = activities[index];
        final color = item['color'] as Color;
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 5,
                offset: const Offset(0, 2),
              )
            ],
          ),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: color.withValues(alpha: 0.1),
              child: Icon(item['icon'] as IconData, color: color, size: 20),
            ),
            title: Text(item['title'] as String, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
            subtitle: Text(item['time'] as String, style: const TextStyle(fontSize: 12, color: Colors.grey)),
          ),
        );
      },
    );
  }
}
