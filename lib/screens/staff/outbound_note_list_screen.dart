import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../models/outbound_note.dart';
import '../../state/warehouse_store.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/status_badge.dart';
import 'outbound_note_form_screen.dart';

class OutboundNoteListScreen extends StatelessWidget {
  const OutboundNoteListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final store = context.watch<WarehouseStore>();
    final notes = store.outboundNotes;

    return Scaffold(
      appBar: AppBar(title: const Text('Phiếu xuất kho')),
      body: notes.isEmpty
          ? const EmptyState(icon: Icons.call_made_rounded, message: 'Chưa có phiếu xuất kho nào')
          : ListView.builder(
              padding: const EdgeInsets.only(bottom: 88, top: 8),
              itemCount: notes.length,
              itemBuilder: (context, index) => _OutboundNoteTile(note: notes[index]),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const OutboundNoteFormScreen()),
        ),
        icon: const Icon(Icons.add),
        label: const Text('Tạo phiếu'),
      ),
    );
  }
}

class _OutboundNoteTile extends StatelessWidget {
  const _OutboundNoteTile({required this.note});

  final OutboundNote note;

  @override
  Widget build(BuildContext context) {
    final dateFmt = DateFormat('dd/MM/yyyy HH:mm');
    final totalQty = note.details.fold<double>(0, (sum, d) => sum + d.quantity);

    return Card(
      child: ListTile(
        title: Text(note.code, style: const TextStyle(fontWeight: FontWeight.w700)),
        subtitle: Text('${note.purpose}\n${dateFmt.format(note.createdAt)}'),
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
