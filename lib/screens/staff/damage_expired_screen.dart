import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../models/batch.dart';
import '../../models/damage_expired_note.dart';
import '../../models/enums.dart';
import '../../state/auth_store.dart';
import '../../state/warehouse_store.dart';
import '../../widgets/app_feedback.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/status_badge.dart';

class DamageExpiredScreen extends StatelessWidget {
  const DamageExpiredScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final store = context.watch<WarehouseStore>();
    final notes = store.damageExpiredNotes;

    return Scaffold(
      appBar: AppBar(title: const Text('Hàng hỏng / hết hạn')),
      body: notes.isEmpty
          ? const EmptyState(icon: Icons.report_gmailerrorred_outlined, message: 'Chưa có phiếu nào')
          : ListView.builder(
              padding: const EdgeInsets.only(bottom: 88, top: 8),
              itemCount: notes.length,
              itemBuilder: (context, index) => _DamageTile(note: notes[index]),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
          builder: (_) => const _DamageExpiredForm(),
        ),
        icon: const Icon(Icons.add),
        label: const Text('Tạo phiếu'),
      ),
    );
  }
}

class _DamageTile extends StatelessWidget {
  const _DamageTile({required this.note});

  final DamageExpiredNote note;

  @override
  Widget build(BuildContext context) {
    final store = context.read<WarehouseStore>();
    final batch = store.batchById(note.batchId);
    final product = batch == null ? null : store.productById(batch.productId);
    final dateFmt = DateFormat('dd/MM/yyyy HH:mm');

    return Card(
      child: ListTile(
        leading: Icon(
          note.type == DamageType.expired ? Icons.event_busy : Icons.broken_image_outlined,
          color: Colors.red[400],
        ),
        title: Text('${product?.name ?? ''} - ${note.type.label}', style: const TextStyle(fontWeight: FontWeight.w700)),
        subtitle: Text('Lô ${batch?.batchCode ?? ''} • ${note.reason}\n${dateFmt.format(note.createdAt)}'),
        isThreeLine: true,
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            StatusBadge(status: note.status),
            const SizedBox(height: 4),
            Text('${note.quantity.toStringAsFixed(0)} kg', style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}

class _DamageExpiredForm extends StatefulWidget {
  const _DamageExpiredForm();

  @override
  State<_DamageExpiredForm> createState() => _DamageExpiredFormState();
}

class _DamageExpiredFormState extends State<_DamageExpiredForm> {
  final _formKey = GlobalKey<FormState>();
  String? _productId;
  String? _batchId;
  DamageType _type = DamageType.damaged;
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
    await store.createDamageExpiredNote(
      batchId: _batchId!,
      quantity: qty,
      type: _type,
      reason: _reasonController.text.trim(),
      createdBy: user.id,
    );
    if (!mounted) return;
    Navigator.of(context).pop();
    showAppSnackBar(context, 'Đã tạo phiếu hàng hỏng/hết hạn, chờ Quản lý kho duyệt');
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<WarehouseStore>();
    final List<Batch> batches = _productId == null ? [] : store.availableBatchesForProduct(_productId!);
    final Batch? selectedBatch = _batchId == null ? null : store.batchById(_batchId!);

    return Padding(
      padding: EdgeInsets.only(left: 20, right: 20, top: 20, bottom: MediaQuery.of(context).viewInsets.bottom + 20),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Tạo phiếu hàng hỏng / hết hạn', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 16),
              SegmentedButton<DamageType>(
                segments: const [
                  ButtonSegment(value: DamageType.damaged, label: Text('Hàng hỏng'), icon: Icon(Icons.broken_image_outlined)),
                  ButtonSegment(value: DamageType.expired, label: Text('Hết hạn'), icon: Icon(Icons.event_busy)),
                ],
                selected: {_type},
                onSelectionChanged: (s) => setState(() => _type = s.first),
              ),
              const SizedBox(height: 12),
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
                decoration: const InputDecoration(labelText: 'Lô hàng'),
                items: batches
                    .map((b) => DropdownMenuItem(
                        value: b.id, child: Text('${b.batchCode} (còn ${b.quantityRemaining.toStringAsFixed(0)}kg)')))
                    .toList(),
                onChanged: (v) => setState(() => _batchId = v),
                validator: (v) => v == null ? 'Chọn lô hàng' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _qtyController,
                decoration: const InputDecoration(labelText: 'Số lượng (kg)'),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: (v) {
                  final n = double.tryParse(v ?? '');
                  if (n == null || n <= 0) return 'Số lượng không hợp lệ';
                  if (selectedBatch != null && n > selectedBatch.quantityRemaining) {
                    return 'Vượt tồn lô (còn ${selectedBatch.quantityRemaining.toStringAsFixed(0)}kg)';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _reasonController,
                decoration: const InputDecoration(labelText: 'Lý do'),
                maxLines: 2,
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Nhập lý do' : null,
              ),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: _submitting ? null : () => _submit(store),
                icon: _submitting
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.send_rounded),
                label: const Text('Gửi duyệt'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
