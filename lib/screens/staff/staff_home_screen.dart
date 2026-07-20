import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../state/auth_store.dart';
import 'adjustment_note_screen.dart';
import 'damage_expired_screen.dart';
import 'inbound_note_list_screen.dart';
import 'inventory_view_screen.dart';
import 'outbound_note_list_screen.dart';
import 'qr_scan_screen.dart';
import 'return_supplier_screen.dart';
import 'stock_check_list_screen.dart';

class StaffHomeScreen extends StatelessWidget {
  const StaffHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthStore>().currentUser;

    final actions = <_StaffAction>[
      _StaffAction(
        title: 'Tồn kho',
        subtitle: 'Xem số lượng tồn theo sản phẩm',
        icon: Icons.inventory_2_outlined,
        builder: (_) => const InventoryViewScreen(),
      ),
      _StaffAction(
        title: 'Phiếu nhập kho',
        subtitle: 'Tạo phiếu nhập, gắn lô hàng',
        icon: Icons.call_received_rounded,
        builder: (_) => const InboundNoteListScreen(),
      ),
      _StaffAction(
        title: 'Phiếu xuất kho',
        subtitle: 'Xuất theo nguyên tắc FEFO',
        icon: Icons.call_made_rounded,
        builder: (_) => const OutboundNoteListScreen(),
      ),
      _StaffAction(
        title: 'Kiểm kê',
        subtitle: 'Đối chiếu tồn hệ thống - thực tế',
        icon: Icons.fact_check_outlined,
        builder: (_) => const StockCheckListScreen(),
      ),
      _StaffAction(
        title: 'Đề xuất điều chỉnh',
        subtitle: 'Báo hao hụt, sai lệch tồn kho',
        icon: Icons.tune_rounded,
        builder: (_) => const AdjustmentNoteScreen(),
      ),
      _StaffAction(
        title: 'Trả hàng NCC',
        subtitle: 'Hàng lỗi / không đạt chất lượng',
        icon: Icons.assignment_return_outlined,
        builder: (_) => const ReturnSupplierScreen(),
      ),
      _StaffAction(
        title: 'Hàng hỏng / hết hạn',
        subtitle: 'Xuất khỏi tồn kho',
        icon: Icons.report_gmailerrorred_outlined,
        builder: (_) => const DamageExpiredScreen(),
      ),
      _StaffAction(
        title: 'Quét mã QR/Barcode',
        subtitle: 'Tra cứu nhanh sản phẩm / lô hàng',
        icon: Icons.qr_code_scanner_rounded,
        builder: (_) => const QrScanScreen(),
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text('Xin chào, ${user?.name ?? ''}'),
        actions: [
          IconButton(
            tooltip: 'Đăng xuất',
            icon: const Icon(Icons.logout),
            onPressed: () => context.read<AuthStore>().logout(),
          ),
        ],
      ),
      body: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 0.95,
        ),
        itemCount: actions.length,
        itemBuilder: (context, index) {
          final action = actions[index];
          return Card(
            margin: EdgeInsets.zero,
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: action.builder)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      radius: 22,
                      backgroundColor: Colors.amber.shade100,
                      child: Icon(action.icon, color: Colors.amber.shade800),
                    ),
                    const Spacer(),
                    Text(action.title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                    const SizedBox(height: 4),
                    Text(
                      action.subtitle,
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _StaffAction {
  const _StaffAction({
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
