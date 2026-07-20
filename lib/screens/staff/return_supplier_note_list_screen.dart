import 'package:flutter/material.dart';
import '../../models/note_status.dart';
import '../../models/return_supplier_note_model.dart';
import '../../services/warehouse_repository.dart';
import '../../utils/date_formatter.dart';
import '../../widgets/note_status_chip.dart';
import 'return_supplier_note_form_screen.dart';

class ReturnSupplierNoteListScreen extends StatefulWidget {
  const ReturnSupplierNoteListScreen({super.key});

  @override
  State<ReturnSupplierNoteListScreen> createState() => _ReturnSupplierNoteListScreenState();
}

class _ReturnSupplierNoteListScreenState extends State<ReturnSupplierNoteListScreen> {
  final _repo = WarehouseRepository.instance;

  Future<void> _openForm({ReturnSupplierNoteModel? note}) async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => ReturnSupplierNoteFormScreen(existing: note)),
    );
    if (result == true && mounted) setState(() {});
  }

  Future<void> _delete(ReturnSupplierNoteModel note) async {
    await _repo.deleteReturnNote(note.id);
    if (!mounted) return;
    setState(() {});
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Đã xoá phiếu trả hàng NCC'), backgroundColor: Colors.green),
    );
  }

  @override
  Widget build(BuildContext context) {
    final notes = _repo.getReturnNotes()..sort((a, b) => b.createdDate.compareTo(a.createdDate));

    return Scaffold(
      body: notes.isEmpty
          ? const Center(child: Text('Chưa có phiếu trả hàng NCC nào', style: TextStyle(color: Colors.grey)))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: notes.length,
              itemBuilder: (context, index) {
                final note = notes[index];
                final product = _repo.findProduct(note.productId);
                final supplier = _repo.findSupplier(note.supplierId);
                final canEdit = NoteStatus.isEditable(note.status);
                return Card(
                  elevation: 1,
                  margin: const EdgeInsets.only(bottom: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: ListTile(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    leading: const CircleAvatar(
                      backgroundColor: Color(0x1F9C27B0),
                      child: Icon(Icons.assignment_return, color: Colors.purple),
                    ),
                    title: Text(note.code, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text(
                        '${product?.name ?? note.productId} → ${supplier?.name ?? note.supplierId}: ${note.quantity}\n${formatDate(note.createdDate)} • ${note.reason}'),
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
