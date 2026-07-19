import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../models/enums.dart';
import '../../models/return_supplier_note.dart';
import '../../state/auth_store.dart';
import '../../state/warehouse_store.dart';
import '../../widgets/app_feedback.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/reason_dialog.dart';
import '../../widgets/status_badge.dart';

/// Duyệt / Từ chối / Huỷ phiếu trả hàng NCC (hàng lỗi/không đạt chất lượng).
class ReturnSupplierApprovalScreen extends StatelessWidget {
  const ReturnSupplierApprovalScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final store = context.watch<WarehouseStore>();
    final notes = store.returnSupplierNotes;

    return Scaffold(
      appBar: AppBar(title: const Text('Duyệt phiếu trả hàng NCC')),
      body: notes.isEmpty
          ? const EmptyState(icon: Icons.assignment_return_outlined, message: 'Chưa có phiếu trả hàng nào')
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: notes.length,
              itemBuilder: (context, index) => _ReturnTile(note: notes[index]),
            ),
    );
  }
}

class _ReturnTile extends StatelessWidget {
  const _ReturnTile({required this.note});

  final ReturnSupplierNote note;

  Future<void> _approve(BuildContext context) async {
    final store = context.read<WarehouseStore>();
    final approver = context.read<AuthStore>().currentUser!;
    final error = await store.approveReturnSupplierNote(note, approver: approver);
    if (!context.mounted) return;
    showAppSnackBar(context, error ?? 'Đã duyệt phiếu trả hàng ${note.code}', isError: error != null);
  }

  Future<void> _reject(BuildContext context) async {
    final reason = await showReasonDialog(context, title: 'Từ chối phiếu ${note.code}', actionLabel: 'Từ chối');
    if (reason == null || !context.mounted) return;
    final store = context.read<WarehouseStore>();
    final approver = context.read<AuthStore>().currentUser!;
    final error = await store.rejectReturnSupplierNote(note, approver: approver, reason: reason);
    if (!context.mounted) return;
    showAppSnackBar(context, error ?? 'Đã từ chối phiếu ${note.code}', isError: error != null);
  }

  Future<void> _cancel(BuildContext context) async {
    final reason = await showReasonDialog(context, title: 'Huỷ phiếu ${note.code}', actionLabel: 'Huỷ phiếu');
    if (reason == null || !context.mounted) return;
    final store = context.read<WarehouseStore>();
    final approver = context.read<AuthStore>().currentUser!;
    final error = await store.cancelReturnSupplierNote(note, approver: approver, reason: reason);
    if (!context.mounted) return;
    showAppSnackBar(context, error ?? 'Đã huỷ phiếu ${note.code}', isError: error != null);
  }

  @override
  Widget build(BuildContext context) {
    final store = context.read<WarehouseStore>();
    final supplier = store.supplierById(note.supplierId);
    final batch = store.batchById(note.batchId);
    final dateFmt = DateFormat('dd/MM/yyyy HH:mm');

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(note.code, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                ),
                StatusBadge(status: note.status),
              ],
            ),
            const SizedBox(height: 4),
            Text('${supplier?.name ?? ''} • Lô ${batch?.batchCode ?? ''} • ${dateFmt.format(note.createdAt)}'),
            Text(note.reason, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
            const SizedBox(height: 4),
            Text('${note.quantity.toStringAsFixed(0)} kg', style: const TextStyle(fontWeight: FontWeight.bold)),
            if (note.rejectReason != null) ...[
              const SizedBox(height: 4),
              Text('Lý do từ chối/huỷ: ${note.rejectReason}', style: TextStyle(fontSize: 12, color: Colors.red[700])),
            ],
            if (note.status == DocumentStatus.pendingApproval) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _reject(context),
                      icon: const Icon(Icons.close, color: Colors.red),
                      label: const Text('Từ chối', style: TextStyle(color: Colors.red)),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () => _approve(context),
                      icon: const Icon(Icons.check),
                      label: const Text('Duyệt'),
                    ),
                  ),
                ],
              ),
            ] else if (note.status == DocumentStatus.approved) ...[
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: () => _cancel(context),
                  icon: const Icon(Icons.undo, color: Colors.grey),
                  label: const Text('Huỷ phiếu', style: TextStyle(color: Colors.grey)),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
