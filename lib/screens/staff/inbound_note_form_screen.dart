import 'package:flutter/material.dart';
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

  @override
  State<InboundNoteFormScreen> createState() => _InboundNoteFormScreenState();
}

class _InboundNoteFormScreenState extends State<InboundNoteFormScreen> {
  final _formKey = GlobalKey<FormState>();
  String? _supplierId;
  final List<_InboundLine> _lines = [];
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
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
  }

  @override
  Widget build(BuildContext context) {
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
          ),
        ),
      ),
    );
  }
}

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
  final _mfgDateKey = GlobalKey<FormFieldState<DateTime>>();
  final _expDateKey = GlobalKey<FormFieldState<DateTime>>();

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
        _mfgDateKey.currentState?.didChange(picked);
        final product = widget.products.where((p) => p.id == widget.line.productId).firstOrNull;
        widget.line.expiryDate ??=
            picked.add(Duration(days: product?.defaultExpiryDays ?? 180));
        if (widget.line.expiryDate != null) {
          _expDateKey.currentState?.didChange(widget.line.expiryDate);
        }
      } else {
        widget.line.expiryDate = picked;
        _expDateKey.currentState?.didChange(picked);
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
              decoration: const InputDecoration(labelText: 'Mã lô', counterText: ''),
              maxLength: 10,
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Nhập mã lô';
                if (v.trim().length > 10) return 'Mã lô tối đa 10 ký tự';
                return null;
              },
            ),
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: FormField<DateTime>(
                    key: _mfgDateKey,
                    initialValue: line.manufactureDate,
                    validator: (v) => v == null ? 'Chọn ngày SX' : null,
                    builder: (field) => Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        OutlinedButton.icon(
                          onPressed: () => _pickDate(isManufactureDate: true),
                          icon: const Icon(Icons.event_outlined, size: 18),
                          label: Text(line.manufactureDate == null ? 'Ngày SX' : _dateFmt.format(line.manufactureDate!)),
                        ),
                        if (field.hasError)
                          Padding(
                            padding: const EdgeInsets.only(left: 12, top: 4),
                            child: Text(
                              field.errorText!,
                              style: TextStyle(color: Theme.of(context).colorScheme.error, fontSize: 12),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: FormField<DateTime>(
                    key: _expDateKey,
                    initialValue: line.expiryDate,
                    validator: (v) {
                      if (v == null) return 'Chọn HSD';
                      if (line.manufactureDate != null && !v.isAfter(line.manufactureDate!)) {
                        return 'HSD phải sau ngày SX';
                      }
                      return null;
                    },
                    builder: (field) => Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        OutlinedButton.icon(
                          onPressed: () => _pickDate(isManufactureDate: false),
                          icon: const Icon(Icons.event_busy_outlined, size: 18),
                          label: Text(line.expiryDate == null ? 'HSD' : _dateFmt.format(line.expiryDate!)),
                        ),
                        if (field.hasError)
                          Padding(
                            padding: const EdgeInsets.only(left: 12, top: 4),
                            child: Text(
                              field.errorText!,
                              style: TextStyle(color: Theme.of(context).colorScheme.error, fontSize: 12),
                            ),
                          ),
                      ],
                    ),
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
