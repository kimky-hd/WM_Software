import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/enums.dart';
import '../../state/warehouse_store.dart';
import 'adjustment_approval_screen.dart';
import 'damage_expired_approval_screen.dart';
import 'inbound_approval_screen.dart';
import 'outbound_approval_screen.dart';
import 'return_supplier_approval_screen.dart';
import 'stock_check_approval_screen.dart';

/// Trung tâm duyệt chứng từ: mỗi loại phiếu hiển thị số lượng đang chờ duyệt,
/// bấm vào để xem toàn bộ danh sách và xử lý Duyệt / Từ chối / Huỷ.
class ManagerApprovalsScreen extends StatelessWidget {
  const ManagerApprovalsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final store = context.watch<WarehouseStore>();

    int pendingOf<T>(List<T> notes, DocumentStatus Function(T) statusOf) =>
        notes.where((n) => statusOf(n) == DocumentStatus.pendingApproval).length;

    final items = <_ApprovalEntry>[
      _ApprovalEntry(
        title: 'Phiếu nhập kho',
        icon: Icons.call_received_rounded,
        pending: pendingOf(store.inboundNotes, (n) => n.status),
        builder: (_) => const InboundApprovalScreen(),
      ),
      _ApprovalEntry(
        title: 'Phiếu xuất kho',
        icon: Icons.call_made_rounded,
        pending: pendingOf(store.outboundNotes, (n) => n.status),
        builder: (_) => const OutboundApprovalScreen(),
      ),
      _ApprovalEntry(
        title: 'Phiếu kiểm kê',
        icon: Icons.fact_check_outlined,
        pending: pendingOf(store.stockCheckNotes, (n) => n.status),
        builder: (_) => const StockCheckApprovalScreen(),
      ),
      _ApprovalEntry(
        title: 'Điều chỉnh tồn kho',
        icon: Icons.tune_rounded,
        pending: pendingOf(store.adjustmentNotes, (n) => n.status),
        builder: (_) => const AdjustmentApprovalScreen(),
      ),
      _ApprovalEntry(
        title: 'Trả hàng NCC',
        icon: Icons.assignment_return_outlined,
        pending: pendingOf(store.returnSupplierNotes, (n) => n.status),
        builder: (_) => const ReturnSupplierApprovalScreen(),
      ),
      _ApprovalEntry(
        title: 'Hàng hỏng / hết hạn',
        icon: Icons.report_gmailerrorred_outlined,
        pending: pendingOf(store.damageExpiredNotes, (n) => n.status),
        builder: (_) => const DamageExpiredApprovalScreen(),
      ),
    ];

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.amber.shade100,
              child: Icon(item.icon, color: Colors.amber.shade800),
            ),
            title: Text(item.title, style: const TextStyle(fontWeight: FontWeight.w600)),
            subtitle: Text(item.pending > 0 ? '${item.pending} phiếu chờ duyệt' : 'Không có phiếu chờ duyệt'),
            trailing: item.pending > 0
                ? Badge(label: Text('${item.pending}'))
                : const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: item.builder)),
          ),
        );
      },
    );
  }
}

class _ApprovalEntry {
  const _ApprovalEntry({
    required this.title,
    required this.icon,
    required this.pending,
    required this.builder,
  });

  final String title;
  final IconData icon;
  final int pending;
  final WidgetBuilder builder;
}
