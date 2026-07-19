import 'package:flutter/material.dart';
import '../../models/note_status.dart';
import '../../models/stock_check_note_model.dart';
import '../../services/warehouse_repository.dart';

class StockCheckNoteFormScreen extends StatefulWidget {
  final StockCheckNoteModel? existing;

  const StockCheckNoteFormScreen({super.key, this.existing});

  @override
  State<StockCheckNoteFormScreen> createState() => _StockCheckNoteFormScreenState();
}

class _CheckRow {
  final String productId;
  final int systemQty;
  final TextEditingController actualQtyController;
  final TextEditingController noteController;

  _CheckRow({required this.productId, required this.systemQty, required int actualQty, required String note})
      : actualQtyController = TextEditingController(text: actualQty.toString()),
        noteController = TextEditingController(text: note);
}

class _StockCheckNoteFormScreenState extends State<StockCheckNoteFormScreen> {
  final _repo = WarehouseRepository.instance;
  final List<_CheckRow> _rows = [];
  bool get _readOnly => widget.existing != null && !NoteStatus.isEditable(widget.existing!.status);

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    if (existing != null) {
      for (final d in existing.details) {
        _rows.add(_CheckRow(
          productId: d.productId,
          systemQty: d.systemQty,
          actualQty: d.actualQty,
          note: d.note,
        ));
      }
    } else {
      for (final p in _repo.getProducts()) {
        final sysQty = _repo.getStockQuantity(p.id);
        _rows.add(_CheckRow(productId: p.id, systemQty: sysQty, actualQty: sysQty, note: ''));
      }
    }
  }

  Future<void> _save() async {
    final details = _rows
        .map((r) => StockCheckDetail(
              productId: r.productId,
              systemQty: r.systemQty,
              actualQty: int.tryParse(r.actualQtyController.text.trim()) ?? r.systemQty,
              note: r.noteController.text.trim(),
            ))
        .toList();

    final note = StockCheckNoteModel(
      id: widget.existing?.id ?? _repo.newId(),
      code: widget.existing?.code ?? _repo.generateNoteCode('PK'),
      checkDate: widget.existing?.checkDate ?? DateTime.now(),
      createdBy: widget.existing?.createdBy ?? WarehouseRepository.currentStaffName,
      status: widget.existing?.status ?? NoteStatus.pending,
      details: details,
    );
    await _repo.saveStockCheckNote(note);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Đã lưu phiếu kiểm kê'), backgroundColor: Colors.green),
    );
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.existing == null ? 'Kiểm kê tồn kho' : 'Phiếu kiểm kê')),
      body: AbsorbPointer(
        absorbing: _readOnly,
        child: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: _rows.length,
          itemBuilder: (context, index) {
            final row = _rows[index];
            final product = _repo.findProduct(row.productId);
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(product?.name ?? row.productId, style: const TextStyle(fontWeight: FontWeight.bold)),
                    Text('Tồn hệ thống: ${row.systemQty} ${product?.unit ?? ''}',
                        style: const TextStyle(fontSize: 12, color: Colors.grey)),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: row.actualQtyController,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: 'Tồn thực tế',
                              prefixIcon: const Icon(Icons.pin),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            onChanged: (_) => setState(() {}),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextFormField(
                            controller: row.noteController,
                            decoration: InputDecoration(
                              labelText: 'Ghi chú',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ),
                      ],
                    ),
                    Builder(builder: (context) {
                      final actual = int.tryParse(row.actualQtyController.text.trim()) ?? row.systemQty;
                      final diff = actual - row.systemQty;
                      if (diff == 0) return const SizedBox.shrink();
                      return Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(
                          diff > 0 ? 'Chênh lệch: +$diff' : 'Chênh lệch: $diff',
                          style: TextStyle(
                              fontSize: 12, fontWeight: FontWeight.bold, color: diff > 0 ? Colors.blue : Colors.red),
                        ),
                      );
                    }),
                  ],
                ),
              ),
            );
          },
        ),
      ),
      floatingActionButton: _readOnly
          ? null
          : FloatingActionButton.extended(
              onPressed: _save,
              icon: const Icon(Icons.save),
              label: const Text('Lưu phiếu'),
            ),
    );
  }
}
