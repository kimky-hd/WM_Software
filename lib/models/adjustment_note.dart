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
  final String? rejectReason;

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
    this.rejectReason,
  });

  AdjustmentNote copyWith({
    DocumentStatus? status,
    String? approvedBy,
    String? batchId,
    String? rejectReason,
  }) =>
      AdjustmentNote(
        id: id,
        code: code,
        createdAt: createdAt,
        productId: productId,
        batchId: batchId ?? this.batchId,
        adjustQty: adjustQty,
        reason: reason,
        proposedBy: proposedBy,
        approvedBy: approvedBy ?? this.approvedBy,
        status: status ?? this.status,
        rejectReason: rejectReason ?? this.rejectReason,
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
        'rejectReason': rejectReason,
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
        rejectReason: json['rejectReason'] as String?,
      );
}
