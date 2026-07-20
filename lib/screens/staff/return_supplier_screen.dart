import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../models/batch.dart';
import '../../models/return_supplier_note.dart';
import '../../state/auth_store.dart';
import '../../state/warehouse_store.dart';
import '../../widgets/app_feedback.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/status_badge.dart';

class ReturnSupplierScreen extends StatelessWidget {
  const ReturnSupplierScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final store = context.watch<WarehouseStore>();
    final notes = store.returnSupplierNotes;

    return Scaffold(
      appBar: AppBar(title: const Text('Phiếu trả hàng NCC')),
      body: notes.isEmpty
          ? const EmptyState(icon: Icons.assignment_return_outlined, message: 'Chưa có phiếu trả hàng nào')
          : ListView.builder(
              padding: const EdgeInsets.only(bottom: 88, top: 8),
              itemCount: notes.length,
              itemBuilder: (context, index) => _ReturnTile(note: notes[index]),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
          builder: (_) => const _ReturnSupplierForm(),
        ),
        icon: const Icon(Icons.add),
        label: const Text('Tạo phiếu'),
      ),
    );
  }
}

class _ReturnTile extends StatelessWidget {
  const _ReturnTile({required this.note});

  final ReturnSupplierNote note;

  @override
  Widget build(BuildContext context) {
    final store = context.read<WarehouseStore>();
    final supplier = store.supplierById(note.supplierId);
    final batch = store.batchById(note.batchId);
    final dateFmt = DateFormat('dd/MM/yyyy HH:mm');

    return Card(
      child: ListTile(
        title: Text(note.code, style: const TextStyle(fontWeight: FontWeight.w700)),
        subtitle: Text(
            '${supplier?.name ?? ''} • Lô ${batch?.batchCode ?? ''}\n${note.reason}\n${dateFmt.format(note.createdAt)}'),
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

class _ReturnSupplierForm extends StatefulWidget {
  const _ReturnSupplierForm();

  @override
  State<_ReturnSupplierForm> createState() => _ReturnSupplierFormState();
}

class _ReturnSupplierFormState extends State<_ReturnSupplierForm> {
  final _formKey = GlobalKey<FormState>();
  String? _supplierId;
  String? _productId;
  String? _batchId;
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
    await store.createReturnSupplierNote(
      supplierId: _supplierId!,
      batchId: _batchId!,
      quantity: qty,
      reason: _reasonController.text.trim(),
      createdBy: user.id,
    );
    if (!mounted) return;
    Navigator.of(context).pop();
    showAppSnackBar(context, 'Đã tạo phiếu trả hàng NCC, chờ Quản lý kho duyệt');
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
              Text('Tạo phiếu trả hàng NCC', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: _supplierId,
                decoration: const InputDecoration(labelText: 'Nhà cung cấp'),
                items: store.suppliers.map((s) => DropdownMenuItem(value: s.id, child: Text(s.name))).toList(),
                onChanged: (v) => setState(() => _supplierId = v),
                validator: (v) => v == null ? 'Chọn nhà cung cấp' : null,
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
                items: batches.map((b) => DropdownMenuItem(value: b.id, child: Text('${b.batchCode} (còn ${b.quantityRemaining.toStringAsFixed(0)}kg)'))).toList(),
                onChanged: (v) => setState(() => _batchId = v),
                validator: (v) => v == null ? 'Chọn lô hàng' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _qtyController,
                decoration: const InputDecoration(labelText: 'Số lượng trả (kg)'),
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
                decoration: const InputDecoration(labelText: 'Lý do (hàng lỗi, không đạt chất lượng...)'),
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
