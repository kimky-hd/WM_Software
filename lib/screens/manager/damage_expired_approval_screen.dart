import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../models/damage_expired_note.dart';
import '../../models/enums.dart';
import '../../state/auth_store.dart';
import '../../state/warehouse_store.dart';
import '../../widgets/app_feedback.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/reason_dialog.dart';
import '../../widgets/status_badge.dart';

/// Duyệt / Từ chối / Huỷ phiếu hàng hỏng / hết hạn (xuất khỏi tồn kho, không
/// tính là bán ra).
class DamageExpiredApprovalScreen extends StatelessWidget {
  const DamageExpiredApprovalScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final store = context.watch<WarehouseStore>();
    final notes = store.damageExpiredNotes;

    return Scaffold(
      appBar: AppBar(title: const Text('Duyệt hàng hỏng / hết hạn')),
      body: notes.isEmpty
          ? const EmptyState(icon: Icons.report_gmailerrorred_outlined, message: 'Chưa có phiếu nào')
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: notes.length,
              itemBuilder: (context, index) => _DamageTile(note: notes[index]),
            ),
    );
  }
}

class _DamageTile extends StatelessWidget {
  const _DamageTile({required this.note});

  final DamageExpiredNote note;

  Future<void> _approve(BuildContext context) async {
    final store = context.read<WarehouseStore>();
    final approver = context.read<AuthStore>().currentUser!;
    final error = await store.approveDamageExpiredNote(note, approver: approver);
    if (!context.mounted) return;
    showAppSnackBar(context, error ?? 'Đã duyệt phiếu ${note.code}', isError: error != null);
  }

  Future<void> _reject(BuildContext context) async {
    final reason = await showReasonDialog(context, title: 'Từ chối phiếu ${note.code}', actionLabel: 'Từ chối');
    if (reason == null || !context.mounted) return;
    final store = context.read<WarehouseStore>();
    final approver = context.read<AuthStore>().currentUser!;
    final error = await store.rejectDamageExpiredNote(note, approver: approver, reason: reason);
    if (!context.mounted) return;
    showAppSnackBar(context, error ?? 'Đã từ chối phiếu ${note.code}', isError: error != null);
  }

  Future<void> _cancel(BuildContext context) async {
    final reason = await showReasonDialog(context, title: 'Huỷ phiếu ${note.code}', actionLabel: 'Huỷ phiếu');
    if (reason == null || !context.mounted) return;
    final store = context.read<WarehouseStore>();
    final approver = context.read<AuthStore>().currentUser!;
    final error = await store.cancelDamageExpiredNote(note, approver: approver, reason: reason);
    if (!context.mounted) return;
    showAppSnackBar(context, error ?? 'Đã huỷ phiếu ${note.code}', isError: error != null);
  }

  @override
  Widget build(BuildContext context) {
    final store = context.read<WarehouseStore>();
    final batch = store.batchById(note.batchId);
    final product = batch == null ? null : store.productById(batch.productId);
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
                Icon(
                  note.type == DamageType.expired ? Icons.event_busy : Icons.broken_image_outlined,
                  color: Colors.red[400],
                  size: 20,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text('${product?.name ?? ''} - ${note.type.label}',
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                ),
                StatusBadge(status: note.status),
              ],
            ),
            const SizedBox(height: 4),
            Text('Lô ${batch?.batchCode ?? ''} • ${dateFmt.format(note.createdAt)}'),
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
