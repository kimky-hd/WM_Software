import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../models/batch.dart';
import '../../models/outbound_note.dart';
import '../../models/product.dart';
import '../../state/auth_store.dart';
import '../../state/warehouse_store.dart';
import '../../widgets/app_feedback.dart';

class OutboundNoteFormScreen extends StatefulWidget {
  const OutboundNoteFormScreen({super.key});

  @override
  State<OutboundNoteFormScreen> createState() => _OutboundNoteFormScreenState();
}

class _OutboundNoteFormScreenState extends State<OutboundNoteFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _purposeController = TextEditingController();
  final List<_OutboundLine> _lines = [];
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _lines.add(_OutboundLine());
  }

  @override
  void dispose() {
    _purposeController.dispose();
    for (final line in _lines) {
      line.dispose();
    }
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final store = context.read<WarehouseStore>();
    final details = <OutboundNoteDetail>[];

    for (final line in _lines) {
      if (line.productId == null) continue;
      for (final alloc in line.allocations) {
        final qty = double.tryParse(alloc.quantityController.text.trim()) ?? 0;
        if (qty <= 0 || alloc.batchId == null) continue;
        final batch = store.batchById(alloc.batchId!);
        if (batch != null && qty > batch.quantityRemaining) {
          showAppSnackBar(
            context,
            'Lô ${batch.batchCode} chỉ còn ${batch.quantityRemaining.toStringAsFixed(0)}kg, không đủ để xuất',
            isError: true,
          );
          return;
        }
        final product = store.productById(line.productId!);
        details.add(OutboundNoteDetail(
          productId: line.productId!,
          batchId: alloc.batchId!,
          quantity: qty,
          unitId: product?.baseUnitId ?? '',
        ));
      }
    }

    if (details.isEmpty) {
      showAppSnackBar(context, 'Cần ít nhất 1 dòng xuất kho hợp lệ', isError: true);
      return;
    }

    final user = context.read<AuthStore>().currentUser!;
    setState(() => _submitting = true);
    await store.createOutboundNote(
      purpose: _purposeController.text.trim(),
      createdBy: user.id,
      details: details,
    );
    if (!mounted) return;
    Navigator.of(context).pop();
    showAppSnackBar(context, 'Đã tạo phiếu xuất kho, chờ Quản lý kho duyệt');
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<WarehouseStore>();

    return Scaffold(
      appBar: AppBar(title: const Text('Tạo phiếu xuất kho')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
          children: [
            TextFormField(
              controller: _purposeController,
              decoration: const InputDecoration(labelText: 'Mục đích xuất', prefixIcon: Icon(Icons.description_outlined)),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Nhập mục đích xuất kho' : null,
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(child: Text('Danh sách hàng xuất (FEFO)', style: Theme.of(context).textTheme.titleMedium)),
              ],
            ),
            const SizedBox(height: 8),
            ..._lines.asMap().entries.map(
                  (e) => _OutboundLineCard(
                    line: e.value,
                    index: e.key,
                    products: store.products,
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
              onPressed: () => setState(() => _lines.add(_OutboundLine())),
              icon: const Icon(Icons.add),
              label: const Text('Thêm sản phẩm'),
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

class _Allocation {
  String? batchId;
  final quantityController = TextEditingController();

  void dispose() => quantityController.dispose();
}

class _OutboundLine {
  String? productId;
  final requestedQtyController = TextEditingController();
  List<_Allocation> allocations = [];

  void dispose() {
    requestedQtyController.dispose();
    for (final a in allocations) {
      a.dispose();
    }
  }
}

class _OutboundLineCard extends StatefulWidget {
  const _OutboundLineCard({
    required this.line,
    required this.index,
    required this.products,
    required this.onRemove,
  });

  final _OutboundLine line;
  final int index;
  final List<Product> products;
  final VoidCallback? onRemove;

  @override
  State<_OutboundLineCard> createState() => _OutboundLineCardState();
}

class _OutboundLineCardState extends State<_OutboundLineCard> {
  final _dateFmt = DateFormat('dd/MM/yyyy');

  void _generateFefoSuggestion() {
    final store = context.read<WarehouseStore>();
    final line = widget.line;
    final qty = double.tryParse(line.requestedQtyController.text.trim()) ?? 0;
    if (line.productId == null || qty <= 0) {
      showAppSnackBar(context, 'Chọn sản phẩm và nhập số lượng cần xuất trước', isError: true);
      return;
    }
    final suggestion = store.suggestFefoAllocation(line.productId!, qty);
    setState(() {
      for (final a in line.allocations) {
        a.dispose();
      }
      line.allocations = suggestion
          .map((s) => _Allocation()
            ..batchId = s.batch.id
            ..quantityController.text = s.quantity.toStringAsFixed(0))
          .toList();
    });
    final allocated = suggestion.fold<double>(0, (sum, s) => sum + s.quantity);
    if (allocated < qty) {
      showAppSnackBar(
        context,
        'Chỉ đủ tồn để xuất ${allocated.toStringAsFixed(0)}/${qty.toStringAsFixed(0)} - kiểm tra lại tồn kho',
        isError: true,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<WarehouseStore>();
    final line = widget.line;
    final availableBatches = line.productId == null ? <Batch>[] : store.availableBatchesForProduct(line.productId!);

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
                  child: Text('Sản phẩm ${widget.index + 1}', style: const TextStyle(fontWeight: FontWeight.w600)),
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
                  .map((p) => DropdownMenuItem(
                      value: p.id, child: Text('${p.code} - ${p.name} (tồn: ${store.totalStockForProduct(p.id).toStringAsFixed(0)}kg)')))
                  .toList(),
              onChanged: (v) => setState(() {
                line.productId = v;
                for (final a in line.allocations) {
                  a.dispose();
                }
                line.allocations = [];
              }),
              validator: (v) => v == null ? 'Chọn sản phẩm' : null,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: line.requestedQtyController,
                    decoration: const InputDecoration(labelText: 'Số lượng cần xuất (kg)'),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    onEditingComplete: _generateFefoSuggestion,
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton.icon(
                  onPressed: _generateFefoSuggestion,
                  icon: const Icon(Icons.auto_fix_high, size: 16),
                  label: const Text('Gợi ý FEFO'),
                ),
              ],
            ),
            if (line.allocations.isNotEmpty) ...[
              const SizedBox(height: 8),
              const Divider(),
              Text('Phân bổ theo lô (HSD gần nhất trước)', style: Theme.of(context).textTheme.labelMedium),
              ...line.allocations.map((alloc) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: DropdownButtonFormField<String>(
                          initialValue: alloc.batchId,
                          isExpanded: true,
                          decoration: const InputDecoration(isDense: true, labelText: 'Lô'),
                          items: availableBatches
                              .map((b) => DropdownMenuItem(
                                  value: b.id,
                                  child: Text('${b.batchCode} (HSD ${_dateFmt.format(b.expiryDate)})', overflow: TextOverflow.ellipsis)))
                              .toList(),
                          onChanged: (v) => setState(() => alloc.batchId = v),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        flex: 2,
                        child: TextFormField(
                          controller: alloc.quantityController,
                          decoration: const InputDecoration(isDense: true, labelText: 'SL'),
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, size: 18),
                        onPressed: () => setState(() {
                          alloc.dispose();
                          line.allocations.remove(alloc);
                        }),
                      ),
                    ],
                  ),
                );
              }),
              TextButton.icon(
                onPressed: availableBatches.isEmpty
                    ? null
                    : () => setState(() => line.allocations.add(_Allocation()..batchId = availableBatches.first.id)),
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Thêm lô thủ công'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
