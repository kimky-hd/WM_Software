import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../models/enums.dart';
import '../../state/warehouse_store.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/stat_card.dart';

/// Báo cáo hao hụt / hàng hỏng - tổng hợp phiếu hàng hỏng/hết hạn và trả hàng
/// NCC đã duyệt, theo nguyên nhân (README mục F).
class DamageReportScreen extends StatelessWidget {
  const DamageReportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final store = context.watch<WarehouseStore>();
    final approvedDamage = store.damageExpiredNotes.where((n) => n.status == DocumentStatus.approved).toList();
    final approvedReturns = store.returnSupplierNotes.where((n) => n.status == DocumentStatus.approved).toList();

    final damagedQty = approvedDamage
        .where((n) => n.type == DamageType.damaged)
        .fold<double>(0, (sum, n) => sum + n.quantity);
    final expiredQty = approvedDamage
        .where((n) => n.type == DamageType.expired)
        .fold<double>(0, (sum, n) => sum + n.quantity);
    final returnedQty = approvedReturns.fold<double>(0, (sum, n) => sum + n.quantity);

    final dateFmt = DateFormat('dd/MM/yyyy');

    return Scaffold(
      appBar: AppBar(title: const Text('Báo cáo hao hụt / hàng hỏng')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          GridView.count(
            crossAxisCount: 3,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 0.95,
            children: [
              StatCard(icon: Icons.broken_image_outlined, label: 'Hàng hỏng (kg)', value: damagedQty.toStringAsFixed(0), color: Colors.red),
              StatCard(icon: Icons.event_busy, label: 'Hết hạn (kg)', value: expiredQty.toStringAsFixed(0), color: Colors.orange),
              StatCard(icon: Icons.assignment_return_outlined, label: 'Trả NCC (kg)', value: returnedQty.toStringAsFixed(0), color: Colors.purple),
            ],
          ),
          const SizedBox(height: 24),
          Text('Chi tiết hàng hỏng / hết hạn', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          if (approvedDamage.isEmpty)
            const EmptyState(icon: Icons.check_circle_outline, message: 'Chưa có phiếu nào được duyệt')
          else
            ...approvedDamage.map((n) {
              final batch = store.batchById(n.batchId);
              final product = batch == null ? null : store.productById(batch.productId);
              return Card(
                child: ListTile(
                  leading: Icon(n.type == DamageType.expired ? Icons.event_busy : Icons.broken_image_outlined, color: Colors.red[400]),
                  title: Text('${product?.name ?? ''} - ${n.type.label}'),
                  subtitle: Text('${n.reason} • ${dateFmt.format(n.createdAt)}'),
                  trailing: Text('${n.quantity.toStringAsFixed(0)} kg', style: const TextStyle(fontWeight: FontWeight.bold)),
                ),
              );
            }),
          const SizedBox(height: 24),
          Text('Chi tiết trả hàng NCC', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          if (approvedReturns.isEmpty)
            const EmptyState(icon: Icons.check_circle_outline, message: 'Chưa có phiếu nào được duyệt')
          else
            ...approvedReturns.map((n) {
              final supplier = store.supplierById(n.supplierId);
              return Card(
                child: ListTile(
                  leading: const Icon(Icons.assignment_return_outlined, color: Colors.purple),
                  title: Text(supplier?.name ?? ''),
                  subtitle: Text('${n.reason} • ${dateFmt.format(n.createdAt)}'),
                  trailing: Text('${n.quantity.toStringAsFixed(0)} kg', style: const TextStyle(fontWeight: FontWeight.bold)),
                ),
              );
            }),
        ],
      ),
    );
  }
}
