import 'package:flutter/material.dart';
<<<<<<< Updated upstream
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
=======
import '../../models/inbound_note_model.dart';
import '../../models/note_status.dart';
import '../../services/warehouse_repository.dart';
import '../../utils/date_formatter.dart';
import '../../widgets/note_status_chip.dart';
import 'inbound_note_form_screen.dart';

class InboundNoteListScreen extends StatefulWidget {
  const InboundNoteListScreen({super.key});

  @override
  State<InboundNoteListScreen> createState() => _InboundNoteListScreenState();
}

class _InboundNoteListScreenState extends State<InboundNoteListScreen> {
  final _repo = WarehouseRepository.instance;

  Future<void> _openForm({InboundNoteModel? note}) async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => InboundNoteFormScreen(existing: note)),
    );
    if (result == true && mounted) setState(() {});
  }

  Future<void> _delete(InboundNoteModel note) async {
    await _repo.deleteInboundNote(note.id);
    if (!mounted) return;
    setState(() {});
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Đã xoá phiếu nhập kho'), backgroundColor: Colors.green),
    );
  }

  @override
  Widget build(BuildContext context) {
    final notes = _repo.getInboundNotes()..sort((a, b) => b.createdDate.compareTo(a.createdDate));

    return Scaffold(
      body: notes.isEmpty
          ? const Center(child: Text('Chưa có phiếu nhập kho nào', style: TextStyle(color: Colors.grey)))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: notes.length,
              itemBuilder: (context, index) {
                final note = notes[index];
                final supplier = _repo.findSupplier(note.supplierId);
                final canEdit = NoteStatus.isEditable(note.status);
                return Card(
                  elevation: 1,
                  margin: const EdgeInsets.only(bottom: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: ListTile(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    leading: const CircleAvatar(
                      backgroundColor: Color(0x1F4CAF50),
                      child: Icon(Icons.call_received, color: Colors.green),
                    ),
                    title: Text(note.code, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text(
                        '${supplier?.name ?? 'NCC không xác định'}\n${formatDate(note.createdDate)} • ${note.details.length} dòng hàng'),
                    isThreeLine: true,
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        NoteStatusChip(status: note.status),
                        if (canEdit)
                          IconButton(
                            icon: const Icon(Icons.delete_outline, color: Colors.red),
                            onPressed: () => _delete(note),
                          ),
                      ],
                    ),
                    onTap: () => _openForm(note: note),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openForm(),
        child: const Icon(Icons.add),
>>>>>>> Stashed changes
      ),
    );
  }
}
