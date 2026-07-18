import 'enums.dart';

/// Phiếu trả hàng NCC - hàng lỗi/không đạt chất lượng khi nhập.
class ReturnSupplierNote {
  final String id;
  final String code;
  final DateTime createdAt;
  final String supplierId;
  final String batchId;
  final double quantity;
  final String reason;
  final String createdBy;
  final String? approvedBy;
  final DocumentStatus status;

  const ReturnSupplierNote({
    required this.id,
    required this.code,
    required this.createdAt,
    required this.supplierId,
    required this.batchId,
    required this.quantity,
    required this.reason,
    required this.createdBy,
    this.approvedBy,
    required this.status,
  });

  ReturnSupplierNote copyWith({DocumentStatus? status, String? approvedBy}) => ReturnSupplierNote(
        id: id,
        code: code,
        createdAt: createdAt,
        supplierId: supplierId,
        batchId: batchId,
        quantity: quantity,
        reason: reason,
        createdBy: createdBy,
        approvedBy: approvedBy ?? this.approvedBy,
        status: status ?? this.status,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'code': code,
        'createdAt': createdAt.toIso8601String(),
        'supplierId': supplierId,
        'batchId': batchId,
        'quantity': quantity,
        'reason': reason,
        'createdBy': createdBy,
        'approvedBy': approvedBy,
        'status': status.name,
      };

  factory ReturnSupplierNote.fromJson(Map<String, dynamic> json) => ReturnSupplierNote(
        id: json['id'] as String,
        code: json['code'] as String,
        createdAt: DateTime.parse(json['createdAt'] as String),
        supplierId: json['supplierId'] as String,
        batchId: json['batchId'] as String,
        quantity: (json['quantity'] as num).toDouble(),
        reason: json['reason'] as String,
        createdBy: json['createdBy'] as String,
        approvedBy: json['approvedBy'] as String?,
        status: DocumentStatus.values.byName(json['status'] as String),
      );
}
