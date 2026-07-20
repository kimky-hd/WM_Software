import 'package:flutter/material.dart';
import '../../models/adjustment_note_model.dart';
import '../../models/note_status.dart';
import '../../services/warehouse_repository.dart';
import '../../utils/date_formatter.dart';
import '../../widgets/note_status_chip.dart';
import 'adjustment_note_form_screen.dart';

class AdjustmentNoteListScreen extends StatefulWidget {
  const AdjustmentNoteListScreen({super.key});

  @override
  State<AdjustmentNoteListScreen> createState() => _AdjustmentNoteListScreenState();
}

class _AdjustmentNoteListScreenState extends State<AdjustmentNoteListScreen> {
  final _repo = WarehouseRepository.instance;

  Future<void> _openForm({AdjustmentNoteModel? note}) async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => AdjustmentNoteFormScreen(existing: note)),
    );
    if (result == true && mounted) setState(() {});
  }

  Future<void> _delete(AdjustmentNoteModel note) async {
    await _repo.deleteAdjustmentNote(note.id);
    if (!mounted) return;
    setState(() {});
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Đã xoá đề xuất điều chỉnh'), backgroundColor: Colors.green),
    );
  }

  @override
  Widget build(BuildContext context) {
    final notes = _repo.getAdjustmentNotes()..sort((a, b) => b.createdDate.compareTo(a.createdDate));

    return Scaffold(
      body: notes.isEmpty
          ? const Center(child: Text('Chưa có đề xuất điều chỉnh nào', style: TextStyle(color: Colors.grey)))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: notes.length,
              itemBuilder: (context, index) {
                final note = notes[index];
                final product = _repo.findProduct(note.productId);
                final canEdit = NoteStatus.isEditable(note.status);
                final isIncrease = note.adjustQuantity >= 0;
                return Card(
                  elevation: 1,
                  margin: const EdgeInsets.only(bottom: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: ListTile(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    leading: CircleAvatar(
                      backgroundColor: (isIncrease ? Colors.blue : Colors.red).withValues(alpha: 0.12),
                      child: Icon(isIncrease ? Icons.arrow_upward : Icons.arrow_downward,
                          color: isIncrease ? Colors.blue : Colors.red),
                    ),
                    title: Text(note.code, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text(
                        '${product?.name ?? note.productId}: ${isIncrease ? '+' : ''}${note.adjustQuantity}\n${formatDate(note.createdDate)} • ${note.reason}'),
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
