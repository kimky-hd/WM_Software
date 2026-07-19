import 'package:flutter/material.dart';

/// Trạng thái vòng đời của các loại chứng từ (phiếu) trong kho.
class NoteStatus {
  static const String draft = 'DRAFT';
  static const String pending = 'PENDING';
  static const String approved = 'APPROVED';
  static const String completed = 'COMPLETED';
  static const String rejected = 'REJECTED';

  static String label(String status) {
    switch (status) {
      case draft:
        return 'Nháp';
      case pending:
        return 'Chờ duyệt';
      case approved:
        return 'Đã duyệt';
      case completed:
        return 'Hoàn thành';
      case rejected:
        return 'Từ chối';
      default:
        return status;
    }
  }

  static Color color(String status) {
    switch (status) {
      case draft:
        return Colors.grey;
      case pending:
        return Colors.orange;
      case approved:
        return Colors.blue;
      case completed:
        return Colors.green;
      case rejected:
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  /// NV kho chỉ được sửa/xoá phiếu khi đang ở trạng thái Chờ duyệt.
  static bool isEditable(String status) => status == pending || status == draft;
}
