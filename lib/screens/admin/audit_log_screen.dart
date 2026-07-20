import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../state/warehouse_store.dart';
import '../../models/audit_log.dart';

class AuditLogScreen extends StatefulWidget {
  const AuditLogScreen({super.key});

  @override
  State<AuditLogScreen> createState() => _AuditLogScreenState();
}

class _AuditLogScreenState extends State<AuditLogScreen> {
  String _searchQuery = '';
  final _dateFormat = DateFormat('HH:mm - dd/MM/yyyy');

  @override
  Widget build(BuildContext context) {
    final store = context.watch<WarehouseStore>();
    final logs = store.auditLogs;
    final primaryColor = Theme.of(context).colorScheme.primary;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: store.isLoading
          ? Center(child: CircularProgressIndicator(color: primaryColor))
          : Column(
              children: [
                _buildSearchBar(),
                Expanded(
                  child: logs.isEmpty
                      ? _buildEmptyState()
                      : _buildListView(primaryColor, logs),
                ),
              ],
            ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.history_toggle_off, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text('Chưa có hoạt động nào', style: TextStyle(color: Colors.grey[600], fontSize: 16)),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: TextField(
        decoration: InputDecoration(
          hintText: 'Tìm kiếm người thực hiện, hành động, mã...',
          prefixIcon: const Icon(Icons.search),
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(vertical: 0),
        ),
        onChanged: (value) {
          setState(() {
            _searchQuery = value.toLowerCase();
          });
        },
      ),
    );
  }

  Widget _buildListView(Color primaryColor, List<AuditLogEntry> logs) {
    final filteredList = logs.where((log) {
      return log.actorName.toLowerCase().contains(_searchQuery) ||
             log.action.toLowerCase().contains(_searchQuery) ||
             log.targetCode.toLowerCase().contains(_searchQuery) ||
             (log.note != null && log.note!.toLowerCase().contains(_searchQuery));
    }).toList();

    if (filteredList.isEmpty) {
      return const Center(child: Text('Không tìm thấy kết quả'));
    }

    return ListView.builder(
      padding: const EdgeInsets.only(top: 16, left: 16, right: 16, bottom: 80),
      itemCount: filteredList.length,
      itemBuilder: (context, index) {
        final log = filteredList[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 8,
                offset: const Offset(0, 3),
              )
            ],
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            leading: CircleAvatar(
              backgroundColor: _getActionColor(log.action).withOpacity(0.1),
              child: Icon(_getActionIcon(log.action), color: _getActionColor(log.action)),
            ),
            title: Row(
              children: [
                Expanded(
                  child: Text(
                    log.action,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                ),
                Text(
                  _dateFormat.format(log.timestamp),
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ],
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.person, size: 14, color: Colors.blue),
                    const SizedBox(width: 4),
                    Text(
                      log.actorName,
                      style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.black87),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.label, size: 14, color: Colors.grey),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        log.targetCode,
                        style: const TextStyle(color: Colors.black54),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                if (log.note != null && log.note!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Text(
                      'Ghi chú: ${log.note}',
                      style: TextStyle(color: Colors.grey.shade800, fontSize: 13, fontStyle: FontStyle.italic),
                    ),
                  ),
                ]
              ],
            ),
          ),
        );
      },
    );
  }

  Color _getActionColor(String action) {
    if (action.toLowerCase().contains('duyệt')) return Colors.green;
    if (action.toLowerCase().contains('từ chối') || action.toLowerCase().contains('huỷ') || action.toLowerCase().contains('xóa') || action.toLowerCase().contains('khoá')) return Colors.red;
    if (action.toLowerCase().contains('cập nhật') || action.toLowerCase().contains('sửa')) return Colors.orange;
    if (action.toLowerCase().contains('thêm') || action.toLowerCase().contains('tạo')) return Colors.blue;
    return Colors.grey;
  }

  IconData _getActionIcon(String action) {
    if (action.toLowerCase().contains('duyệt')) return Icons.check_circle;
    if (action.toLowerCase().contains('từ chối') || action.toLowerCase().contains('huỷ')) return Icons.cancel;
    if (action.toLowerCase().contains('thêm') || action.toLowerCase().contains('tạo')) return Icons.add_circle;
    if (action.toLowerCase().contains('xóa')) return Icons.delete;
    if (action.toLowerCase().contains('cập nhật') || action.toLowerCase().contains('sửa')) return Icons.edit;
    if (action.toLowerCase().contains('khoá')) return Icons.lock;
    return Icons.history;
  }
}
