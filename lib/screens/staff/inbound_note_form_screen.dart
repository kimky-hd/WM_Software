import 'package:flutter/material.dart';
import '../../models/inbound_note_model.dart';
import '../../models/note_status.dart';
import '../../services/warehouse_repository.dart';
import '../../utils/date_formatter.dart';

class InboundNoteFormScreen extends StatefulWidget {
  final InboundNoteModel? existing;

  const InboundNoteFormScreen({super.key, this.existing});

  @override
  State<InboundNoteFormScreen> createState() => _InboundNoteFormScreenState();
}

class _DetailRow {
  String? productId;
  final batchCodeController = TextEditingController();
  final quantityController = TextEditingController();
  String unit = 'kg';
  DateTime manufactureDate = DateTime.now();
  DateTime expiryDate = DateTime.now().add(const Duration(days: 180));

  _DetailRow();

  _DetailRow.fromDetail(InboundNoteDetail d) {
    productId = d.productId;
    batchCodeController.text = d.batchCode;
    quantityController.text = d.quantity.toString();
    unit = d.unit;
    manufactureDate = d.manufactureDate;
    expiryDate = d.expiryDate;
  }
}

class _InboundNoteFormScreenState extends State<InboundNoteFormScreen> {
  final _repo = WarehouseRepository.instance;
  final _formKey = GlobalKey<FormState>();
  String? _supplierId;
  final List<_DetailRow> _rows = [];
  bool get _readOnly => widget.existing != null && !NoteStatus.isEditable(widget.existing!.status);

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    if (existing != null) {
      _supplierId = existing.supplierId;
      _rows.addAll(existing.details.map((d) => _DetailRow.fromDetail(d)));
    } else {
      _rows.add(_DetailRow());
    }
  }

  Future<void> _pickDate(_DetailRow row, {required bool isManufactureDate}) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: isManufactureDate ? row.manufactureDate : row.expiryDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        if (isManufactureDate) {
          row.manufactureDate = picked;
        } else {
          row.expiryDate = picked;
        }
      });
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_supplierId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng chọn nhà cung cấp'), backgroundColor: Colors.red),
      );
      return;
    }
    final details = _rows
        .map((r) => InboundNoteDetail(
              productId: r.productId!,
              batchCode: r.batchCodeController.text.trim(),
              manufactureDate: r.manufactureDate,
              expiryDate: r.expiryDate,
              quantity: int.parse(r.quantityController.text.trim()),
              unit: r.unit,
            ))
        .toList();

    final note = InboundNoteModel(
      id: widget.existing?.id ?? _repo.newId(),
      code: widget.existing?.code ?? _repo.generateNoteCode('PN'),
      createdDate: widget.existing?.createdDate ?? DateTime.now(),
      createdBy: widget.existing?.createdBy ?? WarehouseRepository.currentStaffName,
      supplierId: _supplierId!,
      status: widget.existing?.status ?? NoteStatus.pending,
      details: details,
    );
    await _repo.saveInboundNote(note);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Đã lưu phiếu nhập kho'), backgroundColor: Colors.green),
    );
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final products = _repo.getProducts();
    final suppliers = _repo.getSuppliers();

    return Scaffold(
      appBar: AppBar(title: Text(widget.existing == null ? 'Tạo phiếu nhập kho' : 'Phiếu nhập kho')),
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
              const SizedBox(height: 16),
              const Text('Danh sách hàng nhập', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 8),
              ..._rows.asMap().entries.map((entry) {
                final i = entry.key;
                final row = entry.value;
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: DropdownButtonFormField<String>(
                                initialValue: row.productId,
                                decoration: InputDecoration(
                                  labelText: 'Sản phẩm',
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                                items: products
                                    .map((p) => DropdownMenuItem(value: p.id, child: Text(p.name)))
                                    .toList(),
                                onChanged: (v) => setState(() {
                                  row.productId = v;
                                  final p = v == null ? null : _repo.findProduct(v);
                                  if (p != null) row.unit = p.unit;
                                }),
                                validator: (v) => v == null ? 'Chọn SP' : null,
                              ),
                            ),
                            if (_rows.length > 1)
                              IconButton(
                                icon: const Icon(Icons.remove_circle_outline, color: Colors.red),
                                onPressed: () => setState(() => _rows.removeAt(i)),
                              ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: row.batchCodeController,
                                decoration: InputDecoration(
                                  labelText: 'Mã lô',
                                  prefixIcon: const Icon(Icons.qr_code_2),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                                validator: (v) => (v == null || v.trim().isEmpty) ? 'Bắt buộc' : null,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: TextFormField(
                                controller: row.quantityController,
                                keyboardType: TextInputType.number,
                                decoration: InputDecoration(
                                  labelText: 'Số lượng (${row.unit})',
                                  prefixIcon: const Icon(Icons.numbers),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                                validator: (v) {
                                  final n = int.tryParse(v ?? '');
                                  if (n == null || n <= 0) return 'Số lượng không hợp lệ';
                                  return null;
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                icon: const Icon(Icons.calendar_today, size: 16),
                                label: Text('SX: ${formatDate(row.manufactureDate)}'),
                                onPressed: () => _pickDate(row, isManufactureDate: true),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: OutlinedButton.icon(
                                icon: const Icon(Icons.event_busy, size: 16),
                                label: Text('HSD: ${formatDate(row.expiryDate)}'),
                                onPressed: () => _pickDate(row, isManufactureDate: false),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              }),
              OutlinedButton.icon(
                icon: const Icon(Icons.add),
                label: const Text('Thêm dòng hàng'),
                onPressed: () => setState(() => _rows.add(_DetailRow())),
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
