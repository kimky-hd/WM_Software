import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../models/inbound_note.dart';
import '../../state/warehouse_store.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/status_badge.dart';
import 'inbound_note_form_screen.dart';

class InboundNoteListScreen extends StatelessWidget {
  const InboundNoteListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final store = context.watch<WarehouseStore>();
    final notes = store.inboundNotes;

    return Scaffold(
      appBar: AppBar(title: const Text('Phiếu nhập kho')),
      body: notes.isEmpty
          ? const EmptyState(icon: Icons.call_received_rounded, message: 'Chưa có phiếu nhập kho nào')
          : ListView.builder(
              padding: const EdgeInsets.only(bottom: 88, top: 8),
              itemCount: notes.length,
              itemBuilder: (context, index) => _InboundNoteTile(note: notes[index]),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const InboundNoteFormScreen()),
        ),
        icon: const Icon(Icons.add),
        label: const Text('Tạo phiếu'),
      ),
    );
  }
}

class _InboundNoteTile extends StatelessWidget {
  const _InboundNoteTile({required this.note});

  final InboundNote note;

  @override
  Widget build(BuildContext context) {
    final store = context.read<WarehouseStore>();
    final supplier = store.supplierById(note.supplierId);
    final dateFmt = DateFormat('dd/MM/yyyy HH:mm');
    final totalQty = note.details.fold<double>(0, (sum, d) => sum + d.quantity);

    return Card(
      child: ListTile(
        title: Text(note.code, style: const TextStyle(fontWeight: FontWeight.w700)),
        subtitle: Text('${supplier?.name ?? 'NCC không xác định'}\n${dateFmt.format(note.createdAt)}'),
        isThreeLine: true,
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            StatusBadge(status: note.status),
            const SizedBox(height: 4),
            Text('${note.details.length} dòng • ${totalQty.toStringAsFixed(0)} kg',
                style: TextStyle(fontSize: 11, color: Colors.grey[600])),
          ],
        ),
      ),
    );
  }
}
