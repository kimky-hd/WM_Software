import 'package:flutter/material.dart';
<<<<<<< Updated upstream
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../models/inbound_note.dart';
import '../../models/product.dart';
import '../../models/unit.dart';
import '../../state/auth_store.dart';
import '../../state/warehouse_store.dart';
import '../../widgets/app_feedback.dart';

class InboundNoteFormScreen extends StatefulWidget {
  const InboundNoteFormScreen({super.key});
=======
import '../../models/inbound_note_model.dart';
import '../../models/note_status.dart';
import '../../services/warehouse_repository.dart';
import '../../utils/date_formatter.dart';

class InboundNoteFormScreen extends StatefulWidget {
  final InboundNoteModel? existing;

  const InboundNoteFormScreen({super.key, this.existing});
>>>>>>> Stashed changes

  @override
  State<InboundNoteFormScreen> createState() => _InboundNoteFormScreenState();
}

<<<<<<< Updated upstream
class _InboundNoteFormScreenState extends State<InboundNoteFormScreen> {
  final _formKey = GlobalKey<FormState>();
  String? _supplierId;
  final List<_InboundLine> _lines = [];
  bool _submitting = false;
=======
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
>>>>>>> Stashed changes

  @override
  void initState() {
    super.initState();
<<<<<<< Updated upstream
    _lines.add(_InboundLine());
  }

  @override
  void dispose() {
    for (final line in _lines) {
      line.dispose();
    }
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_lines.isEmpty) {
      showAppSnackBar(context, 'Cần ít nhất 1 dòng sản phẩm', isError: true);
      return;
    }

    final store = context.read<WarehouseStore>();
    final user = context.read<AuthStore>().currentUser!;

    final details = _lines
        .map((l) => InboundNoteDetail(
              productId: l.productId!,
              batchCode: l.batchCodeController.text.trim(),
              manufactureDate: l.manufactureDate!,
              expiryDate: l.expiryDate!,
              quantity: double.parse(l.quantityController.text.trim()),
              unitId: l.unitId!,
            ))
        .toList();

    setState(() => _submitting = true);
    await store.createInboundNote(
      supplierId: _supplierId!,
      createdBy: user.id,
      details: details,
    );
    if (!mounted) return;
    Navigator.of(context).pop();
    showAppSnackBar(context, 'Đã tạo phiếu nhập kho, chờ Quản lý kho duyệt');
=======
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
>>>>>>> Stashed changes
  }

  @override
  Widget build(BuildContext context) {
<<<<<<< Updated upstream
    final store = context.watch<WarehouseStore>();

    return Scaffold(
      appBar: AppBar(title: const Text('Tạo phiếu nhập kho')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
          children: [
            DropdownButtonFormField<String>(
              initialValue: _supplierId,
              decoration: const InputDecoration(labelText: 'Nhà cung cấp', prefixIcon: Icon(Icons.local_shipping_outlined)),
              items: store.suppliers
                  .map((s) => DropdownMenuItem(value: s.id, child: Text(s.name)))
                  .toList(),
              onChanged: (v) => setState(() => _supplierId = v),
              validator: (v) => v == null ? 'Chọn nhà cung cấp' : null,
            ),
            const SizedBox(height: 20),
            Text('Danh sách hàng nhập', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            ..._lines.asMap().entries.map(
                  (e) => _InboundLineCard(
                    line: e.value,
                    index: e.key,
                    products: store.products,
                    units: store.units,
                    onRemove: _lines.length > 1
                        ? () => setState(() {
                              e.value.dispose();
                              _lines.removeAt(e.key);
                            })
                        : null,
                  ),
                ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: () => setState(() => _lines.add(_InboundLine())),
              icon: const Icon(Icons.add),
              label: const Text('Thêm dòng'),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: FilledButton.icon(
            onPressed: _submitting ? null : _submit,
            icon: _submitting
                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.send_rounded),
            label: const Text('Gửi duyệt'),
=======
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
>>>>>>> Stashed changes
          ),
        ),
      ),
    );
  }
}
<<<<<<< Updated upstream

class _InboundLine {
  String? productId;
  String? unitId;
  DateTime? manufactureDate;
  DateTime? expiryDate;
  final batchCodeController = TextEditingController();
  final quantityController = TextEditingController();

  void dispose() {
    batchCodeController.dispose();
    quantityController.dispose();
  }
}

class _InboundLineCard extends StatefulWidget {
  const _InboundLineCard({
    required this.line,
    required this.index,
    required this.products,
    required this.units,
    required this.onRemove,
  });

  final _InboundLine line;
  final int index;
  final List<Product> products;
  final List<UnitOfMeasure> units;
  final VoidCallback? onRemove;

  @override
  State<_InboundLineCard> createState() => _InboundLineCardState();
}

class _InboundLineCardState extends State<_InboundLineCard> {
  final _dateFmt = DateFormat('dd/MM/yyyy');

  Future<void> _pickDate({required bool isManufactureDate}) async {
    final now = DateTime.now();
    final initial = isManufactureDate
        ? (widget.line.manufactureDate ?? now)
        : (widget.line.expiryDate ?? now.add(const Duration(days: 180)));
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(now.year - 2),
      lastDate: DateTime(now.year + 5),
    );
    if (picked == null) return;
    setState(() {
      if (isManufactureDate) {
        widget.line.manufactureDate = picked;
        final product = widget.products.where((p) => p.id == widget.line.productId).firstOrNull;
        widget.line.expiryDate ??=
            picked.add(Duration(days: product?.defaultExpiryDays ?? 180));
      } else {
        widget.line.expiryDate = picked;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final line = widget.line;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text('Dòng ${widget.index + 1}', style: const TextStyle(fontWeight: FontWeight.w600)),
                ),
                if (widget.onRemove != null)
                  IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                    onPressed: widget.onRemove,
                  ),
              ],
            ),
            DropdownButtonFormField<String>(
              initialValue: line.productId,
              decoration: const InputDecoration(labelText: 'Sản phẩm'),
              items: widget.products
                  .map((p) => DropdownMenuItem(value: p.id, child: Text('${p.code} - ${p.name}')))
                  .toList(),
              onChanged: (v) => setState(() {
                line.productId = v;
                line.unitId ??= widget.products.where((p) => p.id == v).firstOrNull?.baseUnitId;
              }),
              validator: (v) => v == null ? 'Chọn sản phẩm' : null,
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: line.batchCodeController,
              decoration: const InputDecoration(labelText: 'Mã lô'),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Nhập mã lô' : null,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _pickDate(isManufactureDate: true),
                    icon: const Icon(Icons.event_outlined, size: 18),
                    label: Text(line.manufactureDate == null ? 'Ngày SX' : _dateFmt.format(line.manufactureDate!)),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _pickDate(isManufactureDate: false),
                    icon: const Icon(Icons.event_busy_outlined, size: 18),
                    label: Text(line.expiryDate == null ? 'HSD' : _dateFmt.format(line.expiryDate!)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: TextFormField(
                    controller: line.quantityController,
                    decoration: const InputDecoration(labelText: 'Số lượng'),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    validator: (v) {
                      final n = double.tryParse(v ?? '');
                      if (n == null || n <= 0) return 'Số lượng không hợp lệ';
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: line.unitId,
                    decoration: const InputDecoration(labelText: 'Đơn vị'),
                    items: widget.units
                        .map((u) => DropdownMenuItem(value: u.id, child: Text(u.name)))
                        .toList(),
                    onChanged: (v) => setState(() => line.unitId = v),
                    validator: (v) => v == null ? 'Chọn đơn vị' : null,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
=======
>>>>>>> Stashed changes
