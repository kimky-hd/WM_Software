import 'package:flutter/material.dart';
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
      ),
    );
  }
}
