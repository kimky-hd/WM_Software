import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../models/batch.dart';
import '../../state/warehouse_store.dart';
import '../../widgets/empty_state.dart';

/// Xem tồn kho - chỉ xem, dành cho Nhân viên kho.
class InventoryViewScreen extends StatefulWidget {
  const InventoryViewScreen({super.key});

  @override
  State<InventoryViewScreen> createState() => _InventoryViewScreenState();
}

class _InventoryViewScreenState extends State<InventoryViewScreen> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final store = context.watch<WarehouseStore>();

    if (store.isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final products = store.products
        .where((p) => p.name.toLowerCase().contains(_query.toLowerCase()) ||
            p.code.toLowerCase().contains(_query.toLowerCase()))
        .toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Tồn kho')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: TextField(
              decoration: const InputDecoration(
                labelText: 'Tìm sản phẩm',
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (v) => setState(() => _query = v),
            ),
          ),
          Expanded(
            child: products.isEmpty
                ? const EmptyState(icon: Icons.inventory_2_outlined, message: 'Không tìm thấy sản phẩm nào')
                : ListView.builder(
                    padding: const EdgeInsets.only(bottom: 16),
                    itemCount: products.length,
                    itemBuilder: (context, index) {
                      final product = products[index];
                      final total = store.totalStockForProduct(product.id);
                      final unit = store.unitById(product.baseUnitId);
                      final batches = store.availableBatchesForProduct(product.id);
                      final isLow = total < product.minStock;

                      return Card(
                        child: ExpansionTile(
                          shape: const Border(),
                          title: Text(product.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                          subtitle: Text('${product.code} • ${product.category}'),
                          trailing: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                '${_fmt(total)} ${unit?.name.split(' ').first ?? ''}',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: isLow ? Colors.red : Colors.black87,
                                ),
                              ),
                              if (isLow)
                                Text('Dưới mức tối thiểu', style: TextStyle(fontSize: 11, color: Colors.red[400])),
                            ],
                          ),
                          children: batches.isEmpty
                              ? [const Padding(padding: EdgeInsets.all(16), child: Text('Không có lô hàng còn tồn'))]
                              : batches.map((b) => _BatchRow(batch: b, unitName: unit?.name ?? '')).toList(),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  String _fmt(double v) => v == v.roundToDouble() ? v.toInt().toString() : v.toStringAsFixed(1);
}

class _BatchRow extends StatelessWidget {
  const _BatchRow({required this.batch, required this.unitName});

  final Batch batch;
  final String unitName;

  @override
  Widget build(BuildContext context) {
    final dateFmt = DateFormat('dd/MM/yyyy');
    final nearExpiry = batch.daysToExpiry <= 7;
    return ListTile(
      dense: true,
      leading: Icon(
        Icons.inventory_outlined,
        color: nearExpiry ? Colors.orange : Colors.grey[500],
      ),
      title: Text(batch.batchCode),
      subtitle: Text('HSD: ${dateFmt.format(batch.expiryDate)}'),
      trailing: Text('${batch.quantityRemaining.toStringAsFixed(0)} kg'),
    );
  }
}
