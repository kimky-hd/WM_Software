import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../models/enums.dart';
import '../../models/outbound_note.dart';
import '../../state/auth_store.dart';
import '../../state/warehouse_store.dart';
import '../../widgets/app_feedback.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/reason_dialog.dart';
import '../../widgets/status_badge.dart';

/// Duyệt / Từ chối / Huỷ phiếu xuất kho. Khi duyệt, hệ thống trừ tồn theo
/// đúng lô đã chọn (FEFO) trong phiếu.
class OutboundApprovalScreen extends StatelessWidget {
  const OutboundApprovalScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final store = context.watch<WarehouseStore>();
    final notes = store.outboundNotes;

    return Scaffold(
      appBar: AppBar(title: const Text('Duyệt phiếu xuất kho')),
      body: notes.isEmpty
          ? const EmptyState(icon: Icons.call_made_rounded, message: 'Chưa có phiếu xuất kho nào')
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: notes.length,
              itemBuilder: (context, index) => _OutboundApprovalTile(note: notes[index]),
            ),
    );
  }
}

class _OutboundApprovalTile extends StatelessWidget {
  const _OutboundApprovalTile({required this.note});

  final OutboundNote note;

  Future<void> _approve(BuildContext context) async {
    final store = context.read<WarehouseStore>();
    final approver = context.read<AuthStore>().currentUser!;
    final error = await store.approveOutboundNote(note, approver: approver);
    if (!context.mounted) return;
    showAppSnackBar(context, error ?? 'Đã duyệt phiếu ${note.code}, đã trừ tồn kho', isError: error != null);
  }

  Future<void> _reject(BuildContext context) async {
    final reason = await showReasonDialog(context, title: 'Từ chối phiếu ${note.code}', actionLabel: 'Từ chối');
    if (reason == null || !context.mounted) return;
    final store = context.read<WarehouseStore>();
    final approver = context.read<AuthStore>().currentUser!;
    final error = await store.rejectOutboundNote(note, approver: approver, reason: reason);
    if (!context.mounted) return;
    showAppSnackBar(context, error ?? 'Đã từ chối phiếu ${note.code}', isError: error != null);
  }

  Future<void> _cancel(BuildContext context) async {
    final reason = await showReasonDialog(context, title: 'Huỷ phiếu ${note.code}', actionLabel: 'Huỷ phiếu');
    if (reason == null || !context.mounted) return;
    final store = context.read<WarehouseStore>();
    final approver = context.read<AuthStore>().currentUser!;
    final error = await store.cancelOutboundNote(note, approver: approver, reason: reason);
    if (!context.mounted) return;
    showAppSnackBar(context, error ?? 'Đã huỷ phiếu ${note.code}', isError: error != null);
  }

  @override
  Widget build(BuildContext context) {
    final dateFmt = DateFormat('dd/MM/yyyy HH:mm');
    final totalQty = note.details.fold<double>(0, (sum, d) => sum + d.quantity);

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
            Text('${note.purpose} • ${dateFmt.format(note.createdAt)}'),
            Text('${note.details.length} dòng • ${totalQty.toStringAsFixed(0)} kg',
                style: TextStyle(fontSize: 12, color: Colors.grey[600])),
            if (note.rejectReason != null) ...[
              const SizedBox(height: 4),
              Text('Lý do: ${note.rejectReason}', style: TextStyle(fontSize: 12, color: Colors.red[700])),
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
