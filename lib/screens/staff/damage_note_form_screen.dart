import 'package:flutter/material.dart';
import '../../models/batch_model.dart';
import '../../models/damage_note_model.dart';
import '../../models/note_status.dart';
import '../../services/warehouse_repository.dart';

class DamageNoteFormScreen extends StatefulWidget {
  final DamageNoteModel? existing;

  const DamageNoteFormScreen({super.key, this.existing});

  @override
  State<DamageNoteFormScreen> createState() => _DamageNoteFormScreenState();
}

class _DamageNoteFormScreenState extends State<DamageNoteFormScreen> {
  final _repo = WarehouseRepository.instance;
  final _formKey = GlobalKey<FormState>();
  String? _productId;
  String? _batchId;
  String _type = DamageType.damaged;
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
      _type = existing.type;
      _quantityController.text = existing.quantity.toString();
      _reasonController.text = existing.reason;
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_productId == null || _batchId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng chọn sản phẩm và lô hàng'), backgroundColor: Colors.red),
      );
      return;
    }

    final note = DamageNoteModel(
      id: widget.existing?.id ?? _repo.newId(),
      code: widget.existing?.code ?? _repo.generateNoteCode('HH'),
      createdDate: widget.existing?.createdDate ?? DateTime.now(),
      createdBy: widget.existing?.createdBy ?? WarehouseRepository.currentStaffName,
      batchId: _batchId!,
      productId: _productId!,
      quantity: int.parse(_quantityController.text.trim()),
      type: _type,
      reason: _reasonController.text.trim(),
      status: widget.existing?.status ?? NoteStatus.pending,
    );
    await _repo.saveDamageNote(note);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Đã lưu phiếu hàng hỏng/hết hạn'), backgroundColor: Colors.green),
    );
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final products = _repo.getProducts();
    final batches = _productId == null ? <BatchModel>[] : _repo.getBatchesForProduct(_productId!);

    return Scaffold(
      appBar: AppBar(title: Text(widget.existing == null ? 'Tạo phiếu hàng hỏng/hết hạn' : 'Phiếu hàng hỏng/hết hạn')),
      body: AbsorbPointer(
        absorbing: _readOnly,
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: DamageType.damaged, label: Text('Hàng hỏng'), icon: Icon(Icons.broken_image)),
                  ButtonSegment(value: DamageType.expired, label: Text('Hết hạn'), icon: Icon(Icons.event_busy)),
                ],
                selected: {_type},
                onSelectionChanged: (v) => setState(() => _type = v.first),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _productId,
                decoration: InputDecoration(
                  labelText: 'Sản phẩm',
                  prefixIcon: const Icon(Icons.inventory_2),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                items: products.map((p) => DropdownMenuItem(value: p.id, child: Text(p.name))).toList(),
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
                  labelText: 'Lô hàng',
                  prefixIcon: const Icon(Icons.qr_code_2),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                items: batches.map((b) => DropdownMenuItem(value: b.id, child: Text(b.batchCode))).toList(),
                onChanged: (v) => setState(() => _batchId = v),
                validator: (v) => v == null ? 'Bắt buộc chọn lô hàng' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _quantityController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Số lượng',
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
                  labelText: 'Lý do',
                  prefixIcon: const Icon(Icons.notes),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Bắt buộc nhập lý do' : null,
              ),
              const SizedBox(height: 24),
              if (!_readOnly)
                FilledButton.icon(
                  icon: const Icon(Icons.save),
                  label: const Text('Lưu phiếu'),
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
