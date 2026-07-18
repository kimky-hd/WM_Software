import 'enums.dart';

/// Phiếu điều chỉnh tồn - Nhân viên kho đề xuất, Quản lý kho duyệt.
class AdjustmentNote {
  final String id;
  final String code;
  final DateTime createdAt;
  final String productId;
  final String? batchId;
  final double adjustQty;
  final String reason;
  final String proposedBy;
  final String? approvedBy;
  final DocumentStatus status;

  const AdjustmentNote({
    required this.id,
    required this.code,
    required this.createdAt,
    required this.productId,
    this.batchId,
    required this.adjustQty,
    required this.reason,
    required this.proposedBy,
    this.approvedBy,
    required this.status,
  });

  AdjustmentNote copyWith({DocumentStatus? status, String? approvedBy}) => AdjustmentNote(
        id: id,
        code: code,
        createdAt: createdAt,
        productId: productId,
        batchId: batchId,
        adjustQty: adjustQty,
        reason: reason,
        proposedBy: proposedBy,
        approvedBy: approvedBy ?? this.approvedBy,
        status: status ?? this.status,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'code': code,
        'createdAt': createdAt.toIso8601String(),
        'productId': productId,
        'batchId': batchId,
        'adjustQty': adjustQty,
        'reason': reason,
        'proposedBy': proposedBy,
        'approvedBy': approvedBy,
        'status': status.name,
      };

  factory AdjustmentNote.fromJson(Map<String, dynamic> json) => AdjustmentNote(
        id: json['id'] as String,
        code: json['code'] as String,
        createdAt: DateTime.parse(json['createdAt'] as String),
        productId: json['productId'] as String,
        batchId: json['batchId'] as String?,
        adjustQty: (json['adjustQty'] as num).toDouble(),
        reason: json['reason'] as String,
        proposedBy: json['proposedBy'] as String,
        approvedBy: json['approvedBy'] as String?,
        status: DocumentStatus.values.byName(json['status'] as String),
      );
}
