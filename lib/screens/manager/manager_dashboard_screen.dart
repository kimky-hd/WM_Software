import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../models/batch.dart';
import '../../models/product.dart';
import '../../state/warehouse_store.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/stat_card.dart';

/// Tổng quan hệ thống dành cho Quản lý kho: tổng SP, tổng tồn, phiếu chờ duyệt,
/// và các cảnh báo tồn thấp / sắp hết hạn / hết hạn (theo README mục E & F).
class ManagerDashboardScreen extends StatelessWidget {
  const ManagerDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final store = context.watch<WarehouseStore>();

    if (store.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final totalStock = store.products.fold<double>(0, (sum, p) => sum + store.totalStockForProduct(p.id));
    final lowStock = store.lowStockProducts;
    final expiringSoon = store.expiringSoonBatches();
    final expired = store.expiredBatches;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.5,
          children: [
            StatCard(
              icon: Icons.inventory_2_outlined,
              label: 'Tổng sản phẩm',
              value: '${store.products.length}',
              color: Colors.blue,
            ),
            StatCard(
              icon: Icons.warehouse_outlined,
              label: 'Tổng tồn kho (kg)',
              value: totalStock.toStringAsFixed(0),
              color: Colors.teal,
            ),
            StatCard(
              icon: Icons.fact_check_outlined,
              label: 'Phiếu chờ duyệt',
              value: '${store.pendingApprovalCount}',
              color: Colors.orange,
            ),
            StatCard(
              icon: Icons.warning_amber_outlined,
              label: 'Cảnh báo hiện có',
              value: '${lowStock.length + expiringSoon.length + expired.length}',
              color: Colors.red,
            ),
          ],
        ),
        const SizedBox(height: 24),
        Text('Tồn kho thấp', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        if (lowStock.isEmpty)
          const EmptyState(icon: Icons.check_circle_outline, message: 'Không có sản phẩm nào dưới mức tối thiểu')
        else
          ...lowStock.map((p) => _LowStockTile(product: p, store: store)),
        const SizedBox(height: 24),
        Text('Sắp hết hạn (≤ 7 ngày)', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        if (expiringSoon.isEmpty)
          const EmptyState(icon: Icons.check_circle_outline, message: 'Không có lô hàng nào sắp hết hạn')
        else
          ...expiringSoon.map((b) => _BatchAlertTile(batch: b, store: store, isExpired: false)),
        const SizedBox(height: 24),
        Text('Đã hết hạn - chưa xử lý', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        if (expired.isEmpty)
          const EmptyState(icon: Icons.check_circle_outline, message: 'Không có lô hàng nào quá hạn')
        else
          ...expired.map((b) => _BatchAlertTile(batch: b, store: store, isExpired: true)),
      ],
    );
  }
}

class _LowStockTile extends StatelessWidget {
  const _LowStockTile({required this.product, required this.store});

  final Product product;
  final WarehouseStore store;

  @override
  Widget build(BuildContext context) {
    final total = store.totalStockForProduct(product.id);
    return Card(
      child: ListTile(
        leading: const Icon(Icons.trending_down, color: Colors.red),
        title: Text(product.name),
        subtitle: Text('${product.code} • Tối thiểu: ${product.minStock.toStringAsFixed(0)}'),
        trailing: Text('${total.toStringAsFixed(0)} kg', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
      ),
    );
  }
}

class _BatchAlertTile extends StatelessWidget {
  const _BatchAlertTile({required this.batch, required this.store, required this.isExpired});

  final Batch batch;
  final WarehouseStore store;
  final bool isExpired;

  @override
  Widget build(BuildContext context) {
    final product = store.productById(batch.productId);
    final dateFmt = DateFormat('dd/MM/yyyy');
    return Card(
      child: ListTile(
        leading: Icon(isExpired ? Icons.event_busy : Icons.schedule, color: isExpired ? Colors.red : Colors.orange),
        title: Text(product?.name ?? batch.productId),
        subtitle: Text('Lô ${batch.batchCode} • HSD: ${dateFmt.format(batch.expiryDate)}'),
        trailing: Text('${batch.quantityRemaining.toStringAsFixed(0)} kg', style: const TextStyle(fontWeight: FontWeight.bold)),
      ),
    );
  }
}
