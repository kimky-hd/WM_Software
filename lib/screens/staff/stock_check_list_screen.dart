import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../models/stock_check_note.dart';
import '../../state/warehouse_store.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/status_badge.dart';
import 'stock_check_form_screen.dart';

class StockCheckListScreen extends StatelessWidget {
  const StockCheckListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final store = context.watch<WarehouseStore>();
    final notes = store.stockCheckNotes;

    return Scaffold(
      appBar: AppBar(title: const Text('Kiểm kê')),
      body: notes.isEmpty
          ? const EmptyState(icon: Icons.fact_check_outlined, message: 'Chưa có phiếu kiểm kê nào')
          : ListView.builder(
              padding: const EdgeInsets.only(bottom: 88, top: 8),
              itemCount: notes.length,
              itemBuilder: (context, index) => _StockCheckTile(note: notes[index]),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const StockCheckFormScreen()),
        ),
        icon: const Icon(Icons.add),
        label: const Text('Kiểm kê mới'),
      ),
    );
  }
}

class _StockCheckTile extends StatelessWidget {
  const _StockCheckTile({required this.note});

  final StockCheckNote note;

  @override
  Widget build(BuildContext context) {
    final dateFmt = DateFormat('dd/MM/yyyy HH:mm');
    final diffCount = note.details.where((d) => d.difference != 0).length;

    return Card(
      child: ListTile(
        title: Text(note.code, style: const TextStyle(fontWeight: FontWeight.w700)),
        subtitle: Text(dateFmt.format(note.checkDate)),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            StatusBadge(status: note.status),
            const SizedBox(height: 4),
            Text(
              diffCount == 0 ? 'Khớp tồn kho' : '$diffCount sản phẩm lệch',
              style: TextStyle(fontSize: 11, color: diffCount == 0 ? Colors.green : Colors.orange[700]),
            ),
          ],
        ),
      ),
    );
  }
}
