import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../state/warehouse_store.dart';
import '../../widgets/empty_state.dart';

/// Đơn vị tính & quy đổi - Quản lý kho chỉ có quyền Xem.
class UnitCatalogScreen extends StatelessWidget {
  const UnitCatalogScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final units = context.watch<WarehouseStore>().units;

    return Scaffold(
      appBar: AppBar(title: const Text('Đơn vị tính & quy đổi')),
      body: units.isEmpty
          ? const EmptyState(icon: Icons.straighten_outlined, message: 'Chưa có đơn vị tính nào')
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: units.length,
              itemBuilder: (context, index) {
                final unit = units[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: const Icon(Icons.straighten_outlined),
                    title: Text(unit.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                    trailing: Text('x${unit.conversionFactor.toStringAsFixed(unit.conversionFactor == unit.conversionFactor.roundToDouble() ? 0 : 2)} kg'),
                  ),
                );
              },
            ),
    );
  }
}
