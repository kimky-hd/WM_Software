import 'package:flutter/material.dart';
import '../../models/adjustment_note_model.dart';
import '../../models/batch_model.dart';
import '../../models/note_status.dart';
import '../../services/warehouse_repository.dart';

class AdjustmentNoteFormScreen extends StatefulWidget {
  final AdjustmentNoteModel? existing;

  const AdjustmentNoteFormScreen({super.key, this.existing});

  @override
  State<AdjustmentNoteFormScreen> createState() => _AdjustmentNoteFormScreenState();
}

class _AdjustmentNoteFormScreenState extends State<AdjustmentNoteFormScreen> {
  final _repo = WarehouseRepository.instance;
  final _formKey = GlobalKey<FormState>();
  String? _productId;
  String? _batchId;
  bool _isIncrease = false;
  final _quantityController = TextEditingController();
  final _reasonController = TextEditingController();
  bool get _readOnly => widget.existing != null && !NoteStatus.isEditable(widget.existing!.status);

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    if (existing != null) {
      _productId = existing.productId;
      _batchId = existing.batchId;
      _isIncrease = existing.adjustQuantity >= 0;
      _quantityController.text = existing.adjustQuantity.abs().toString();
      _reasonController.text = existing.reason;
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final qty = int.parse(_quantityController.text.trim());

    final note = AdjustmentNoteModel(
      id: widget.existing?.id ?? _repo.newId(),
      code: widget.existing?.code ?? _repo.generateNoteCode('DC'),
      createdDate: widget.existing?.createdDate ?? DateTime.now(),
      createdBy: widget.existing?.createdBy ?? WarehouseRepository.currentStaffName,
      productId: _productId!,
      batchId: _batchId,
      adjustQuantity: _isIncrease ? qty : -qty,
      reason: _reasonController.text.trim(),
      status: widget.existing?.status ?? NoteStatus.pending,
    );
    await _repo.saveAdjustmentNote(note);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Đã lưu đề xuất điều chỉnh tồn'), backgroundColor: Colors.green),
    );
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final products = _repo.getProducts();
    final batches = _productId == null ? <BatchModel>[] : _repo.getBatchesForProduct(_productId!);

    return Scaffold(
      appBar: AppBar(title: Text(widget.existing == null ? 'Đề xuất điều chỉnh tồn' : 'Điều chỉnh tồn kho')),
      body: AbsorbPointer(
        absorbing: _readOnly,
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              DropdownButtonFormField<String>(
                initialValue: _productId,
                decoration: InputDecoration(
                  labelText: 'Sản phẩm',
                  prefixIcon: const Icon(Icons.inventory_2),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                items: products
                    .map((p) => DropdownMenuItem(
                        value: p.id, child: Text('${p.name} (tồn ${_repo.getStockQuantity(p.id)})')))
                    .toList(),
                onChanged: (v) => setState(() {
                  _productId = v;
                  _batchId = null;
                }),
                validator: (v) => v == null ? 'Bắt buộc chọn sản phẩm' : null,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _batchId,
                decoration: InputDecoration(
                  labelText: 'Lô hàng (tuỳ chọn)',
                  prefixIcon: const Icon(Icons.qr_code_2),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                items: batches
                    .map((b) => DropdownMenuItem(value: b.id, child: Text(b.batchCode)))
                    .toList(),
                onChanged: (v) => setState(() => _batchId = v),
              ),
              const SizedBox(height: 12),
              SegmentedButton<bool>(
                segments: const [
                  ButtonSegment(value: true, label: Text('Tăng tồn'), icon: Icon(Icons.arrow_upward)),
                  ButtonSegment(value: false, label: Text('Giảm tồn'), icon: Icon(Icons.arrow_downward)),
                ],
                selected: {_isIncrease},
                onSelectionChanged: (v) => setState(() => _isIncrease = v.first),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _quantityController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Số lượng điều chỉnh',
                  prefixIcon: const Icon(Icons.numbers),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                validator: (v) {
                  final n = int.tryParse(v ?? '');
                  if (n == null || n <= 0) return 'Số lượng không hợp lệ';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _reasonController,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: 'Lý do (hao hụt, sai lệch kiểm kê...)',
                  prefixIcon: const Icon(Icons.notes),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Bắt buộc nhập lý do' : null,
              ),
              const SizedBox(height: 24),
              if (!_readOnly)
                FilledButton.icon(
                  icon: const Icon(Icons.save),
                  label: const Text('Lưu đề xuất'),
                  onPressed: _save,
                  style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
