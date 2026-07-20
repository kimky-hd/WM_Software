import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../state/warehouse_store.dart';
import '../../widgets/empty_state.dart';

/// Nhật ký hoạt động (Audit Log) - ai duyệt/từ chối/huỷ gì, thời điểm nào
/// (README mục G). Quản lý kho chỉ xem được log của kho mình.
class AuditLogScreen extends StatelessWidget {
  const AuditLogScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final logs = context.watch<WarehouseStore>().auditLogs;
    final dateFmt = DateFormat('dd/MM/yyyy HH:mm');

    return Scaffold(
      appBar: AppBar(title: const Text('Nhật ký hoạt động')),
      body: logs.isEmpty
          ? const EmptyState(icon: Icons.history, message: 'Chưa có hoạt động nào được ghi nhận')
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: logs.length,
              itemBuilder: (context, index) {
                final log = logs[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.amber.shade100,
                      child: Icon(_iconFor(log.action), color: Colors.amber.shade800, size: 20),
                    ),
                    title: Text('${log.action} • ${log.targetCode}', style: const TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: Text(
                      '${log.actorName} • ${dateFmt.format(log.timestamp)}'
                      '${log.note != null ? '\nLý do: ${log.note}' : ''}',
                    ),
                    isThreeLine: log.note != null,
                  ),
                );
              },
            ),
    );
  }

  IconData _iconFor(String action) {
    if (action.startsWith('Duyệt')) return Icons.check_circle_outline;
    if (action.startsWith('Từ chối')) return Icons.cancel_outlined;
    if (action.startsWith('Huỷ')) return Icons.undo_outlined;
    if (action.startsWith('Đề xuất')) return Icons.rate_review_outlined;
    return Icons.history;
  }
}
