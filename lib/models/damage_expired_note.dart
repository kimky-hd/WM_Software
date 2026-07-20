import 'enums.dart';

/// Phiếu hàng hỏng/hết hạn - xuất khỏi tồn kho, không tính là bán ra.
class DamageExpiredNote {
  final String id;
  final String code;
  final DateTime createdAt;
  final String batchId;
  final double quantity;
  final DamageType type;
  final String reason;
  final String createdBy;
  final String? approvedBy;
  final DocumentStatus status;
  final String? rejectReason;

  const DamageExpiredNote({
    required this.id,
    required this.code,
    required this.createdAt,
    required this.batchId,
    required this.quantity,
    required this.type,
    required this.reason,
    required this.createdBy,
    this.approvedBy,
    required this.status,
    this.rejectReason,
  });

  DamageExpiredNote copyWith({DocumentStatus? status, String? approvedBy, String? rejectReason}) =>
      DamageExpiredNote(
        id: id,
        code: code,
        createdAt: createdAt,
        batchId: batchId,
        quantity: quantity,
        type: type,
        reason: reason,
        createdBy: createdBy,
        approvedBy: approvedBy ?? this.approvedBy,
        status: status ?? this.status,
        rejectReason: rejectReason ?? this.rejectReason,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'code': code,
        'createdAt': createdAt.toIso8601String(),
        'batchId': batchId,
        'quantity': quantity,
        'type': type.name,
        'reason': reason,
        'createdBy': createdBy,
        'approvedBy': approvedBy,
        'status': status.name,
        'rejectReason': rejectReason,
      };

  factory DamageExpiredNote.fromJson(Map<String, dynamic> json) => DamageExpiredNote(
        id: json['id'] as String,
        code: json['code'] as String,
        createdAt: DateTime.parse(json['createdAt'] as String),
        batchId: json['batchId'] as String,
        quantity: (json['quantity'] as num).toDouble(),
        type: DamageType.values.byName(json['type'] as String),
        reason: json['reason'] as String,
        createdBy: json['createdBy'] as String,
        approvedBy: json['approvedBy'] as String?,
        status: DocumentStatus.values.byName(json['status'] as String),
        rejectReason: json['rejectReason'] as String?,
      );
}
