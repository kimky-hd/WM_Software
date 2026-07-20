import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../state/auth_store.dart';
import '../../state/warehouse_store.dart';
import 'admin_alerts_screen.dart';

class DashboardScreen extends StatelessWidget {
  final Function(int)? onNavigate;
  const DashboardScreen({super.key, this.onNavigate});

  @override
  Widget build(BuildContext context) {
    final store = context.watch<WarehouseStore>();

    if (store.isLoading) {
      return const Center(child: CircularProgressIndicator(color: Colors.amber));
    }

    final totalProducts = store.products.length;
    final totalSuppliers = store.suppliers.length;
    final totalAlerts = store.lowStockProducts.length + store.expiringSoonBatches().length + store.expiredBatches.length;
    final totalUsers = context.watch<AuthStore>().allUsers.length;

    return RefreshIndicator(
      color: Colors.amber,
      onRefresh: () async => store.init(),
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
                _buildStatCard('Sản phẩm', totalProducts.toString(), Icons.inventory_2, Colors.blue, onTap: () => onNavigate?.call(1)),
                _buildStatCard('Đối tác', totalSuppliers.toString(), Icons.local_shipping, Colors.green, onTap: () => onNavigate?.call(2)),
                _buildStatCard('Tài khoản', totalUsers.toString(), Icons.people, Colors.purple, onTap: () {
                  onNavigate?.call(3);
                }),
                _buildStatCard('Cảnh báo', totalAlerts.toString(), Icons.warning_amber, Colors.orange, onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminAlertsScreen()));
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
                _buildQuickAction(Icons.category, 'Sản phẩm', Colors.blue, onTap: () {
                  onNavigate?.call(1);
                }),
                _buildQuickAction(Icons.local_shipping, 'Đối tác', Colors.teal, onTap: () {
                  onNavigate?.call(2);
                }),
                _buildQuickAction(Icons.people, 'Tài khoản', Colors.orange, onTap: () {
                  onNavigate?.call(3);
                }),
                _buildQuickAction(Icons.history, 'Nhật ký', Colors.indigo, onTap: () {
                  onNavigate?.call(4);
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
                  onPressed: () => onNavigate?.call(4),
                  child: const Text('Xem tất cả', style: TextStyle(color: Colors.amber, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            const SizedBox(height: 8),
            _buildActivityList(store),
            
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
              color: Colors.black.withOpacity(0.04),
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
              color: color.withOpacity(0.1),
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

  Widget _buildActivityList(WarehouseStore store) {
    final logs = store.auditLogs.take(5).toList();

    if (logs.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Center(
          child: Text('Chưa có hoạt động nào được ghi nhận', style: TextStyle(color: Colors.grey)),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: logs.length,
      itemBuilder: (context, index) {
        final log = logs[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.02),
                blurRadius: 5,
                offset: const Offset(0, 2),
              )
            ],
          ),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.amber.withOpacity(0.1),
              child: const Icon(Icons.history, color: Colors.amber, size: 20),
            ),
            title: Text(
              '${log.actorName}: ${log.action}',
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Text(
              '${log.targetCode} • ${_formatTime(log.timestamp)}',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ),
        );
      },
    );
  }

  String _formatTime(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return 'Vừa xong';
    if (diff.inMinutes < 60) return '${diff.inMinutes} phút trước';
    if (diff.inHours < 24) return '${diff.inHours} giờ trước';
    return '${dt.day}/${dt.month}/${dt.year}';
  }
}
