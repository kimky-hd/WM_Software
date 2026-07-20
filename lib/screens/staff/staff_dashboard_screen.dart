import 'package:flutter/material.dart';
import '../../models/note_status.dart';
import '../../services/warehouse_repository.dart';

class StaffDashboardScreen extends StatefulWidget {
  final void Function(int index, String title)? onNavigate;

  const StaffDashboardScreen({super.key, this.onNavigate});

  @override
  State<StaffDashboardScreen> createState() => _StaffDashboardScreenState();
}

class _StaffDashboardScreenState extends State<StaffDashboardScreen> {
  final _repo = WarehouseRepository.instance;

  @override
  Widget build(BuildContext context) {
    final pendingCount = _repo.getInboundNotes().where((n) => n.status == NoteStatus.pending).length +
        _repo.getOutboundNotes().where((n) => n.status == NoteStatus.pending).length +
        _repo.getStockCheckNotes().where((n) => n.status == NoteStatus.pending).length +
        _repo.getAdjustmentNotes().where((n) => n.status == NoteStatus.pending).length +
        _repo.getReturnNotes().where((n) => n.status == NoteStatus.pending).length +
        _repo.getDamageNotes().where((n) => n.status == NoteStatus.pending).length;

    final totalProducts = _repo.getProducts().length;
    final lowStockCount = _repo.getProducts().where((p) => _repo.getStockQuantity(p.id) < p.minStockLevel).length;

    return RefreshIndicator(
      onRefresh: () async => setState(() {}),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('Xin chào, ${WarehouseRepository.currentStaffName}!',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          const Text('Tổng quan công việc hôm nay', style: TextStyle(color: Colors.grey)),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _StatCard(
                  icon: Icons.pending_actions,
                  label: 'Phiếu chờ duyệt',
                  value: '$pendingCount',
                  color: Colors.orange,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatCard(
                  icon: Icons.inventory_2,
                  label: 'Mặt hàng',
                  value: '$totalProducts',
                  color: Colors.blue,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatCard(
                  icon: Icons.warning_amber,
                  label: 'Sắp/dưới mức tồn',
                  value: '$lowStockCount',
                  color: Colors.red,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          const Text('Thao tác nhanh', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          _QuickAction(
            icon: Icons.call_received,
            label: 'Tạo Phiếu nhập kho',
            color: Colors.green,
            onTap: () => widget.onNavigate?.call(2, 'Phiếu nhập kho'),
          ),
          _QuickAction(
            icon: Icons.call_made,
            label: 'Tạo Phiếu xuất kho',
            color: Colors.deepOrange,
            onTap: () => widget.onNavigate?.call(3, 'Phiếu xuất kho'),
          ),
          _QuickAction(
            icon: Icons.fact_check,
            label: 'Tạo Phiếu kiểm kê',
            color: Colors.indigo,
            onTap: () => widget.onNavigate?.call(4, 'Phiếu kiểm kê'),
          ),
          _QuickAction(
            icon: Icons.inventory,
            label: 'Xem tồn kho',
            color: Colors.teal,
            onTap: () => widget.onNavigate?.call(1, 'Tồn kho'),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatCard({required this.icon, required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 2),
            Text(label, textAlign: TextAlign.center, style: const TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickAction({required this.icon, required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        leading: CircleAvatar(backgroundColor: color.withValues(alpha: 0.15), child: Icon(icon, color: color)),
        title: Text(label),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
