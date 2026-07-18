import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../models/adjustment_note.dart';
import '../../models/batch.dart';
import '../../state/auth_store.dart';
import '../../state/warehouse_store.dart';
import '../../widgets/app_feedback.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/status_badge.dart';

class AdjustmentNoteScreen extends StatelessWidget {
  const AdjustmentNoteScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final store = context.watch<WarehouseStore>();
    final notes = store.adjustmentNotes;

    return Scaffold(
      appBar: AppBar(title: const Text('Đề xuất điều chỉnh tồn kho')),
      body: notes.isEmpty
          ? const EmptyState(icon: Icons.tune_rounded, message: 'Chưa có đề xuất điều chỉnh nào')
          : ListView.builder(
              padding: const EdgeInsets.only(bottom: 88, top: 8),
              itemCount: notes.length,
              itemBuilder: (context, index) => _AdjustmentTile(note: notes[index]),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAdjustmentForm(context),
        icon: const Icon(Icons.add),
        label: const Text('Đề xuất'),
      ),
    );
  }

  void _showAdjustmentForm(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => const _AdjustmentForm(),
    );
  }
}

class _AdjustmentTile extends StatelessWidget {
  const _AdjustmentTile({required this.note});

  final AdjustmentNote note;

  @override
  Widget build(BuildContext context) {
    final store = context.read<WarehouseStore>();
    final product = store.productById(note.productId);
    final dateFmt = DateFormat('dd/MM/yyyy HH:mm');
    final isPositive = note.adjustQty >= 0;

    return Card(
      child: ListTile(
        title: Text(product?.name ?? note.productId, style: const TextStyle(fontWeight: FontWeight.w700)),
        subtitle: Text('${note.reason}\n${dateFmt.format(note.createdAt)}'),
        isThreeLine: true,
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            StatusBadge(status: note.status),
            const SizedBox(height: 4),
            Text(
              '${isPositive ? '+' : ''}${note.adjustQty.toStringAsFixed(0)} kg',
              style: TextStyle(fontWeight: FontWeight.bold, color: isPositive ? Colors.green[700] : Colors.red[700]),
            ),
          ],
        ),
      ),
    );
  }
}

class _AdjustmentForm extends StatefulWidget {
  const _AdjustmentForm();

  @override
  State<_AdjustmentForm> createState() => _AdjustmentFormState();
}

class _AdjustmentFormState extends State<_AdjustmentForm> {
  final _formKey = GlobalKey<FormState>();
  String? _productId;
  String? _batchId;
  bool _isDecrease = true;
  final _qtyController = TextEditingController();
  final _reasonController = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _qtyController.dispose();
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _submit(WarehouseStore store) async {
    if (!_formKey.currentState!.validate()) return;
    final qty = double.parse(_qtyController.text.trim());
    final user = context.read<AuthStore>().currentUser!;

    setState(() => _submitting = true);
    await store.createAdjustmentNote(
      productId: _productId!,
      batchId: _batchId,
      adjustQty: _isDecrease ? -qty : qty,
      reason: _reasonController.text.trim(),
      proposedBy: user.id,
    );
    if (!mounted) return;
    Navigator.of(context).pop();
    showAppSnackBar(context, 'Đã gửi đề xuất điều chỉnh, chờ Quản lý kho duyệt');
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<WarehouseStore>();
    final List<Batch> batches = _productId == null ? [] : store.availableBatchesForProduct(_productId!);

    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Đề xuất điều chỉnh tồn kho', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: _productId,
                decoration: const InputDecoration(labelText: 'Sản phẩm'),
                items: store.products.map((p) => DropdownMenuItem(value: p.id, child: Text(p.name))).toList(),
                onChanged: (v) => setState(() {
                  _productId = v;
                  _batchId = null;
                }),
                validator: (v) => v == null ? 'Chọn sản phẩm' : null,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _batchId,
                decoration: const InputDecoration(labelText: 'Lô hàng (không bắt buộc)'),
                items: batches
                    .map((b) => DropdownMenuItem(value: b.id, child: Text(b.batchCode)))
                    .toList(),
                onChanged: (v) => setState(() => _batchId = v),
              ),
              const SizedBox(height: 12),
              SegmentedButton<bool>(
                segments: const [
                  ButtonSegment(value: true, label: Text('Giảm tồn'), icon: Icon(Icons.remove)),
                  ButtonSegment(value: false, label: Text('Tăng tồn'), icon: Icon(Icons.add)),
                ],
                selected: {_isDecrease},
                onSelectionChanged: (s) => setState(() => _isDecrease = s.first),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _qtyController,
                decoration: const InputDecoration(labelText: 'Số lượng chênh lệch (kg)'),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: (v) {
                  final n = double.tryParse(v ?? '');
                  if (n == null || n <= 0) return 'Số lượng không hợp lệ';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _reasonController,
                decoration: const InputDecoration(labelText: 'Lý do (hao hụt, sai lệch kiểm kê...)'),
                maxLines: 2,
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Nhập lý do' : null,
              ),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: _submitting ? null : () => _submit(store),
                icon: _submitting
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.send_rounded),
                label: const Text('Gửi đề xuất'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
