import 'package:flutter/material.dart';

import '../staff/inventory_view_screen.dart';
import 'audit_log_screen.dart';
import 'damage_report_screen.dart';

/// Báo cáo & Nhật ký - Quản lý kho xem toàn bộ báo cáo của kho mình (README mục F, G).
class ManagerReportsScreen extends StatelessWidget {
  const ManagerReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final items = <_ReportEntry>[
      _ReportEntry(
        title: 'Tồn kho theo lô',
        subtitle: 'Từng lô còn bao nhiêu, HSD còn bao lâu',
        icon: Icons.inventory_2_outlined,
        builder: (_) => const InventoryViewScreen(),
      ),
      _ReportEntry(
        title: 'Báo cáo hao hụt / hàng hỏng',
        subtitle: 'Tổng hợp theo kỳ, theo nguyên nhân',
        icon: Icons.report_gmailerrorred_outlined,
        builder: (_) => const DamageReportScreen(),
      ),
      _ReportEntry(
        title: 'Nhật ký hoạt động',
        subtitle: 'Ai duyệt/từ chối/huỷ gì, thời điểm nào',
        icon: Icons.history,
        builder: (_) => const AuditLogScreen(),
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
            subtitle: Text(item.subtitle),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: item.builder)),
          ),
        );
      },
    );
  }
}

class _ReportEntry {
  const _ReportEntry({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.builder,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final WidgetBuilder builder;
}
