import 'package:flutter/material.dart';
import '../../models/damage_note_model.dart';
import '../../models/note_status.dart';
import '../../services/warehouse_repository.dart';
import '../../utils/date_formatter.dart';
import '../../widgets/note_status_chip.dart';
import 'damage_note_form_screen.dart';

class DamageNoteListScreen extends StatefulWidget {
  const DamageNoteListScreen({super.key});

  @override
  State<DamageNoteListScreen> createState() => _DamageNoteListScreenState();
}

class _DamageNoteListScreenState extends State<DamageNoteListScreen> {
  final _repo = WarehouseRepository.instance;

  Future<void> _openForm({DamageNoteModel? note}) async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => DamageNoteFormScreen(existing: note)),
    );
    if (result == true && mounted) setState(() {});
  }

  Future<void> _delete(DamageNoteModel note) async {
    await _repo.deleteDamageNote(note.id);
    if (!mounted) return;
    setState(() {});
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Đã xoá phiếu hàng hỏng/hết hạn'), backgroundColor: Colors.green),
    );
  }

  @override
  Widget build(BuildContext context) {
    final notes = _repo.getDamageNotes()..sort((a, b) => b.createdDate.compareTo(a.createdDate));

    return Scaffold(
      body: notes.isEmpty
          ? const Center(child: Text('Chưa có phiếu hàng hỏng/hết hạn nào', style: TextStyle(color: Colors.grey)))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: notes.length,
              itemBuilder: (context, index) {
                final note = notes[index];
                final product = _repo.findProduct(note.productId);
                final canEdit = NoteStatus.isEditable(note.status);
                return Card(
                  elevation: 1,
                  margin: const EdgeInsets.only(bottom: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: ListTile(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    leading: const CircleAvatar(
                      backgroundColor: Color(0x1F795548),
                      child: Icon(Icons.report_problem_outlined, color: Colors.brown),
                    ),
                    title: Text(note.code, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text(
                        '${product?.name ?? note.productId} • ${DamageType.label(note.type)}: ${note.quantity}\n${formatDate(note.createdDate)} • ${note.reason}'),
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
