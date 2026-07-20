import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../models/batch.dart';
import '../../models/product.dart';
import '../../state/warehouse_store.dart';

class AdminAlertsScreen extends StatelessWidget {
  const AdminAlertsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final store = context.watch<WarehouseStore>();

    final lowStock = store.lowStockProducts;
    final expiringSoon = store.expiringSoonBatches();
    final expired = store.expiredBatches;

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Cảnh báo Hệ thống'),
          bottom: TabBar(
            isScrollable: true,
            labelColor: Theme.of(context).colorScheme.primary,
            unselectedLabelColor: Colors.grey,
            tabs: [
              Tab(
                child: Row(
                  children: [
                    const Icon(Icons.warning_amber, color: Colors.orange),
                    const SizedBox(width: 8),
                    Text('Tồn thấp (${lowStock.length})'),
                  ],
                ),
              ),
              Tab(
                child: Row(
                  children: [
                    const Icon(Icons.schedule, color: Colors.orangeAccent),
                    const SizedBox(width: 8),
                    Text('Sắp hết hạn (${expiringSoon.length})'),
                  ],
                ),
              ),
              Tab(
                child: Row(
                  children: [
                    const Icon(Icons.event_busy, color: Colors.red),
                    const SizedBox(width: 8),
                    Text('Hết hạn (${expired.length})'),
                  ],
                ),
              ),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildLowStockList(lowStock, store),
            _buildExpiringSoonList(expiringSoon, store),
            _buildExpiredList(expired, store),
          ],
        ),
      ),
    );
  }

  Widget _buildLowStockList(List<Product> products, WarehouseStore store) {
    if (products.isEmpty) {
      return _buildEmptyState(Icons.check_circle_outline, 'Không có sản phẩm nào dưới mức tồn kho tối thiểu.');
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: products.length,
      itemBuilder: (context, index) {
        final p = products[index];
        final total = store.totalStockForProduct(p.id);
        return Card(
          elevation: 2,
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: const Icon(Icons.trending_down, color: Colors.orange),
            title: Text(p.name, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text('Mã: ${p.code} • Tối thiểu: ${p.minStock.toStringAsFixed(0)}'),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('${total.toStringAsFixed(0)} kg', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.orange)),
                const Text('Hiện tại', style: TextStyle(fontSize: 12, color: Colors.grey)),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildExpiringSoonList(List<Batch> batches, WarehouseStore store) {
    if (batches.isEmpty) {
      return _buildEmptyState(Icons.check_circle_outline, 'Không có lô hàng nào sắp hết hạn trong 7 ngày tới.');
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: batches.length,
      itemBuilder: (context, index) {
        return _buildBatchTile(batches[index], store, isExpired: false);
      },
    );
  }

  Widget _buildExpiredList(List<Batch> batches, WarehouseStore store) {
    if (batches.isEmpty) {
      return _buildEmptyState(Icons.check_circle_outline, 'Tuyệt vời! Không có lô hàng nào quá hạn.');
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: batches.length,
      itemBuilder: (context, index) {
        return _buildBatchTile(batches[index], store, isExpired: true);
      },
    );
  }

  Widget _buildBatchTile(Batch batch, WarehouseStore store, {required bool isExpired}) {
    final product = store.productById(batch.productId);
    final dateFmt = DateFormat('dd/MM/yyyy');
    final color = isExpired ? Colors.red : Colors.orangeAccent;
    final icon = isExpired ? Icons.event_busy : Icons.schedule;

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Icon(icon, color: color),
        title: Text(product?.name ?? batch.productId, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text('Lô: ${batch.batchCode}'),
            Text('HSD: ${dateFmt.format(batch.expiryDate)}', style: TextStyle(color: color, fontWeight: FontWeight.bold)),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text('${batch.quantityRemaining.toStringAsFixed(0)} kg', style: const TextStyle(fontWeight: FontWeight.bold)),
            const Text('Tồn lô', style: TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(IconData icon, String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64, color: Colors.green),
          const SizedBox(height: 16),
          Text(message, style: const TextStyle(color: Colors.grey, fontSize: 16)),
        ],
      ),
    );
  }
}
