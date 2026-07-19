import 'package:flutter/material.dart';
import '../../models/batch_model.dart';
import '../../models/note_status.dart';
import '../../models/return_supplier_note_model.dart';
import '../../services/warehouse_repository.dart';

class ReturnSupplierNoteFormScreen extends StatefulWidget {
  final ReturnSupplierNoteModel? existing;

  const ReturnSupplierNoteFormScreen({super.key, this.existing});

  @override
  State<ReturnSupplierNoteFormScreen> createState() => _ReturnSupplierNoteFormScreenState();
}

class _ReturnSupplierNoteFormScreenState extends State<ReturnSupplierNoteFormScreen> {
  final _repo = WarehouseRepository.instance;
  final _formKey = GlobalKey<FormState>();
  String? _supplierId;
  String? _productId;
  String? _batchId;
  final _quantityController = TextEditingController();
  final _reasonController = TextEditingController();
  bool get _readOnly => widget.existing != null && !NoteStatus.isEditable(widget.existing!.status);

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    if (existing != null) {
      _supplierId = existing.supplierId;
      _productId = existing.productId;
      _batchId = existing.batchId;
      _quantityController.text = existing.quantity.toString();
      _reasonController.text = existing.reason;
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_supplierId == null || _productId == null || _batchId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng chọn đầy đủ NCC, sản phẩm và lô hàng'), backgroundColor: Colors.red),
      );
      return;
    }

    final note = ReturnSupplierNoteModel(
      id: widget.existing?.id ?? _repo.newId(),
      code: widget.existing?.code ?? _repo.generateNoteCode('TH'),
      createdDate: widget.existing?.createdDate ?? DateTime.now(),
      createdBy: widget.existing?.createdBy ?? WarehouseRepository.currentStaffName,
      supplierId: _supplierId!,
      batchId: _batchId!,
      productId: _productId!,
      quantity: int.parse(_quantityController.text.trim()),
      reason: _reasonController.text.trim(),
      status: widget.existing?.status ?? NoteStatus.pending,
    );
    await _repo.saveReturnNote(note);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Đã lưu phiếu trả hàng NCC'), backgroundColor: Colors.green),
    );
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final suppliers = _repo.getSuppliers();
    final products = _repo.getProducts();
    final batches = _productId == null ? <BatchModel>[] : _repo.getBatchesForProduct(_productId!);

    return Scaffold(
      appBar: AppBar(title: Text(widget.existing == null ? 'Tạo phiếu trả hàng NCC' : 'Phiếu trả hàng NCC')),
      body: AbsorbPointer(
        absorbing: _readOnly,
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              DropdownButtonFormField<String>(
                initialValue: _supplierId,
                decoration: InputDecoration(
                  labelText: 'Nhà cung cấp',
                  prefixIcon: const Icon(Icons.local_shipping),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                items: suppliers.map((s) => DropdownMenuItem(value: s.id, child: Text(s.name))).toList(),
                onChanged: (v) => setState(() => _supplierId = v),
                validator: (v) => v == null ? 'Bắt buộc chọn nhà cung cấp' : null,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _productId,
                decoration: InputDecoration(
                  labelText: 'Sản phẩm lỗi/không đạt',
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
                  labelText: 'Số lượng trả',
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
                  labelText: 'Lý do trả hàng',
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
