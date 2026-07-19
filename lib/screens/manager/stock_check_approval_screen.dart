import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../models/enums.dart';
import '../../models/stock_check_note.dart';
import '../../state/auth_store.dart';
import '../../state/warehouse_store.dart';
import '../../widgets/app_feedback.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/reason_dialog.dart';
import '../../widgets/status_badge.dart';

/// Duyệt / Từ chối / Huỷ phiếu kiểm kê. Phiếu chỉ ghi nhận chênh lệch giữa tồn
/// hệ thống và tồn thực tế - việc sửa tồn thực hiện qua Phiếu điều chỉnh riêng.
class StockCheckApprovalScreen extends StatelessWidget {
  const StockCheckApprovalScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final store = context.watch<WarehouseStore>();
    final notes = store.stockCheckNotes;

    return Scaffold(
      appBar: AppBar(title: const Text('Duyệt phiếu kiểm kê')),
      body: notes.isEmpty
          ? const EmptyState(icon: Icons.fact_check_outlined, message: 'Chưa có phiếu kiểm kê nào')
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: notes.length,
              itemBuilder: (context, index) => _StockCheckTile(note: notes[index]),
            ),
    );
  }
}

class _StockCheckTile extends StatelessWidget {
  const _StockCheckTile({required this.note});

  final StockCheckNote note;

  Future<void> _approve(BuildContext context) async {
    final store = context.read<WarehouseStore>();
    final approver = context.read<AuthStore>().currentUser!;
    final error = await store.approveStockCheckNote(note, approver: approver);
    if (!context.mounted) return;
    showAppSnackBar(context, error ?? 'Đã duyệt phiếu kiểm kê ${note.code}', isError: error != null);
  }

  Future<void> _reject(BuildContext context) async {
    final reason = await showReasonDialog(context, title: 'Từ chối phiếu ${note.code}', actionLabel: 'Từ chối');
    if (reason == null || !context.mounted) return;
    final store = context.read<WarehouseStore>();
    final approver = context.read<AuthStore>().currentUser!;
    final error = await store.rejectStockCheckNote(note, approver: approver, reason: reason);
    if (!context.mounted) return;
    showAppSnackBar(context, error ?? 'Đã từ chối phiếu ${note.code}', isError: error != null);
  }

  Future<void> _cancel(BuildContext context) async {
    final reason = await showReasonDialog(context, title: 'Huỷ phiếu ${note.code}', actionLabel: 'Huỷ phiếu');
    if (reason == null || !context.mounted) return;
    final store = context.read<WarehouseStore>();
    final approver = context.read<AuthStore>().currentUser!;
    final error = await store.cancelStockCheckNote(note, approver: approver, reason: reason);
    if (!context.mounted) return;
    showAppSnackBar(context, error ?? 'Đã huỷ phiếu ${note.code}', isError: error != null);
  }

  @override
  Widget build(BuildContext context) {
    final store = context.read<WarehouseStore>();
    final dateFmt = DateFormat('dd/MM/yyyy HH:mm');
    final diffCount = note.details.where((d) => d.difference != 0).length;

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
            Text('Kiểm ngày ${dateFmt.format(note.checkDate)} • $diffCount sản phẩm lệch tồn'),
            if (note.rejectReason != null) ...[
              const SizedBox(height: 4),
              Text('Lý do: ${note.rejectReason}', style: TextStyle(fontSize: 12, color: Colors.red[700])),
            ],
            const SizedBox(height: 4),
            ExpansionTile(
              tilePadding: EdgeInsets.zero,
              title: const Text('Chi tiết chênh lệch', style: TextStyle(fontSize: 13)),
              children: note.details.where((d) => d.difference != 0).map((d) {
                final product = store.productById(d.productId);
                final isPositive = d.difference > 0;
                return ListTile(
                  dense: true,
                  title: Text(product?.name ?? d.productId),
                  subtitle: Text('Hệ thống: ${d.systemQty.toStringAsFixed(0)} • Thực tế: ${d.actualQty.toStringAsFixed(0)}'),
                  trailing: Text(
                    '${isPositive ? '+' : ''}${d.difference.toStringAsFixed(0)}',
                    style: TextStyle(fontWeight: FontWeight.bold, color: isPositive ? Colors.green[700] : Colors.red[700]),
                  ),
                );
              }).toList(),
            ),
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
