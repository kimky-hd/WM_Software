import 'package:flutter/material.dart';
import '../../models/note_status.dart';
import '../../models/stock_check_note_model.dart';
import '../../services/warehouse_repository.dart';
import '../../utils/date_formatter.dart';
import '../../widgets/note_status_chip.dart';
import 'stock_check_note_form_screen.dart';

class StockCheckNoteListScreen extends StatefulWidget {
  const StockCheckNoteListScreen({super.key});

  @override
  State<StockCheckNoteListScreen> createState() => _StockCheckNoteListScreenState();
}

class _StockCheckNoteListScreenState extends State<StockCheckNoteListScreen> {
  final _repo = WarehouseRepository.instance;

  Future<void> _openForm({StockCheckNoteModel? note}) async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => StockCheckNoteFormScreen(existing: note)),
    );
    if (result == true && mounted) setState(() {});
  }

  Future<void> _delete(StockCheckNoteModel note) async {
    await _repo.deleteStockCheckNote(note.id);
    if (!mounted) return;
    setState(() {});
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Đã xoá phiếu kiểm kê'), backgroundColor: Colors.green),
    );
  }

  @override
  Widget build(BuildContext context) {
    final notes = _repo.getStockCheckNotes()..sort((a, b) => b.checkDate.compareTo(a.checkDate));

    return Scaffold(
      body: notes.isEmpty
          ? const Center(child: Text('Chưa có phiếu kiểm kê nào', style: TextStyle(color: Colors.grey)))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: notes.length,
              itemBuilder: (context, index) {
                final note = notes[index];
                final canEdit = NoteStatus.isEditable(note.status);
                final diffCount = note.details.where((d) => d.difference != 0).length;
                return Card(
                  elevation: 1,
                  margin: const EdgeInsets.only(bottom: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: ListTile(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    leading: const CircleAvatar(
                      backgroundColor: Color(0x1F3F51B5),
                      child: Icon(Icons.fact_check, color: Colors.indigo),
                    ),
                    title: Text(note.code, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text(
                        '${formatDate(note.checkDate)} • ${note.details.length} SP kiểm • $diffCount SP chênh lệch'),
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
