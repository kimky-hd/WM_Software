import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../models/enums.dart';
import '../../models/inbound_note.dart';
import '../../state/auth_store.dart';
import '../../state/warehouse_store.dart';
import '../../widgets/app_feedback.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/reason_dialog.dart';
import '../../widgets/status_badge.dart';

/// Duyệt / Từ chối / Huỷ phiếu nhập kho. Khi duyệt, hệ thống tự tạo Batch mới
/// (theo đúng luồng 5.1 trong README) và cộng vào tồn kho.
class InboundApprovalScreen extends StatelessWidget {
  const InboundApprovalScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final store = context.watch<WarehouseStore>();
    final notes = store.inboundNotes;

    return Scaffold(
      appBar: AppBar(title: const Text('Duyệt phiếu nhập kho')),
      body: notes.isEmpty
          ? const EmptyState(icon: Icons.call_received_rounded, message: 'Chưa có phiếu nhập kho nào')
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: notes.length,
              itemBuilder: (context, index) => _InboundApprovalTile(note: notes[index]),
            ),
    );
  }
}

class _InboundApprovalTile extends StatelessWidget {
  const _InboundApprovalTile({required this.note});

  final InboundNote note;

  Future<void> _approve(BuildContext context) async {
    final store = context.read<WarehouseStore>();
    final approver = context.read<AuthStore>().currentUser!;
    final error = await store.approveInboundNote(note, approver: approver);
    if (!context.mounted) return;
    showAppSnackBar(context, error ?? 'Đã duyệt phiếu ${note.code}, đã tạo lô hàng mới', isError: error != null);
  }

  Future<void> _reject(BuildContext context) async {
    final reason = await showReasonDialog(context, title: 'Từ chối phiếu ${note.code}', actionLabel: 'Từ chối');
    if (reason == null || !context.mounted) return;
    final store = context.read<WarehouseStore>();
    final approver = context.read<AuthStore>().currentUser!;
    final error = await store.rejectInboundNote(note, approver: approver, reason: reason);
    if (!context.mounted) return;
    showAppSnackBar(context, error ?? 'Đã từ chối phiếu ${note.code}', isError: error != null);
  }

  Future<void> _cancel(BuildContext context) async {
    final reason = await showReasonDialog(context, title: 'Huỷ phiếu ${note.code}', actionLabel: 'Huỷ phiếu');
    if (reason == null || !context.mounted) return;
    final store = context.read<WarehouseStore>();
    final approver = context.read<AuthStore>().currentUser!;
    final error = await store.cancelInboundNote(note, approver: approver, reason: reason);
    if (!context.mounted) return;
    showAppSnackBar(context, error ?? 'Đã huỷ phiếu ${note.code}', isError: error != null);
  }

  @override
  Widget build(BuildContext context) {
    final store = context.read<WarehouseStore>();
    final supplier = store.supplierById(note.supplierId);
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
            Text('${supplier?.name ?? 'NCC không xác định'} • ${dateFmt.format(note.createdAt)}'),
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
