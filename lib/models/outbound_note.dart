import 'enums.dart';

/// Dòng chi tiết phiếu xuất - xuất từ 1 lô cụ thể (gợi ý theo FEFO).
class OutboundNoteDetail {
  final String productId;
  final String batchId;
  final double quantity;
  final String unitId;

  const OutboundNoteDetail({
    required this.productId,
    required this.batchId,
    required this.quantity,
    required this.unitId,
  });

  Map<String, dynamic> toJson() => {
        'productId': productId,
        'batchId': batchId,
        'quantity': quantity,
        'unitId': unitId,
      };

  factory OutboundNoteDetail.fromJson(Map<String, dynamic> json) => OutboundNoteDetail(
        productId: json['productId'] as String,
        batchId: json['batchId'] as String,
        quantity: (json['quantity'] as num).toDouble(),
        unitId: json['unitId'] as String,
      );
}

class OutboundNote {
  final String id;
  final String code;
  final DateTime createdAt;
  final String createdBy;
  final String? approvedBy;
  final DocumentStatus status;
  final String purpose;
  final List<OutboundNoteDetail> details;
  final String? rejectReason;

  const OutboundNote({
    required this.id,
    required this.code,
    required this.createdAt,
    required this.createdBy,
    this.approvedBy,
    required this.status,
    required this.purpose,
    required this.details,
    this.rejectReason,
  });

  OutboundNote copyWith({
    DocumentStatus? status,
    String? approvedBy,
    String? rejectReason,
  }) =>
      OutboundNote(
        id: id,
        code: code,
        createdAt: createdAt,
        createdBy: createdBy,
        approvedBy: approvedBy ?? this.approvedBy,
        status: status ?? this.status,
        purpose: purpose,
        details: details,
        rejectReason: rejectReason ?? this.rejectReason,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'code': code,
        'createdAt': createdAt.toIso8601String(),
        'createdBy': createdBy,
        'approvedBy': approvedBy,
        'status': status.name,
        'purpose': purpose,
        'details': details.map((d) => d.toJson()).toList(),
        'rejectReason': rejectReason,
      };

  factory OutboundNote.fromJson(Map<String, dynamic> json) => OutboundNote(
        id: json['id'] as String,
        code: json['code'] as String,
        createdAt: DateTime.parse(json['createdAt'] as String),
        createdBy: json['createdBy'] as String,
        approvedBy: json['approvedBy'] as String?,
        status: DocumentStatus.values.byName(json['status'] as String),
        purpose: json['purpose'] as String,
        details: (json['details'] as List)
            .map((d) => OutboundNoteDetail.fromJson(d as Map<String, dynamic>))
            .toList(),
        rejectReason: json['rejectReason'] as String?,
      );
}
