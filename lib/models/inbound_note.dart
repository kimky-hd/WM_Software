import 'enums.dart';

/// Dòng chi tiết phiếu nhập - mỗi dòng tạo ra 1 lô hàng mới.
class InboundNoteDetail {
  final String productId;
  final String batchCode;
  final DateTime manufactureDate;
  final DateTime expiryDate;
  final double quantity;
  final String unitId;

  const InboundNoteDetail({
    required this.productId,
    required this.batchCode,
    required this.manufactureDate,
    required this.expiryDate,
    required this.quantity,
    required this.unitId,
  });

  Map<String, dynamic> toJson() => {
        'productId': productId,
        'batchCode': batchCode,
        'manufactureDate': manufactureDate.toIso8601String(),
        'expiryDate': expiryDate.toIso8601String(),
        'quantity': quantity,
        'unitId': unitId,
      };

  factory InboundNoteDetail.fromJson(Map<String, dynamic> json) => InboundNoteDetail(
        productId: json['productId'] as String,
        batchCode: json['batchCode'] as String,
        manufactureDate: DateTime.parse(json['manufactureDate'] as String),
        expiryDate: DateTime.parse(json['expiryDate'] as String),
        quantity: (json['quantity'] as num).toDouble(),
        unitId: json['unitId'] as String,
      );
}

class InboundNote {
  final String id;
  final String code;
  final DateTime createdAt;
  final String createdBy;
  final String? approvedBy;
  final DocumentStatus status;
  final String supplierId;
  final List<InboundNoteDetail> details;
  final String? rejectReason;

  const InboundNote({
    required this.id,
    required this.code,
    required this.createdAt,
    required this.createdBy,
    this.approvedBy,
    required this.status,
    required this.supplierId,
    required this.details,
    this.rejectReason,
  });

  InboundNote copyWith({
    DocumentStatus? status,
    String? approvedBy,
    String? rejectReason,
  }) =>
      InboundNote(
        id: id,
        code: code,
        createdAt: createdAt,
        createdBy: createdBy,
        approvedBy: approvedBy ?? this.approvedBy,
        status: status ?? this.status,
        supplierId: supplierId,
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
        'supplierId': supplierId,
        'details': details.map((d) => d.toJson()).toList(),
        'rejectReason': rejectReason,
      };

  factory InboundNote.fromJson(Map<String, dynamic> json) => InboundNote(
        id: json['id'] as String,
        code: json['code'] as String,
        createdAt: DateTime.parse(json['createdAt'] as String),
        createdBy: json['createdBy'] as String,
        approvedBy: json['approvedBy'] as String?,
        status: DocumentStatus.values.byName(json['status'] as String),
        supplierId: json['supplierId'] as String,
        details: (json['details'] as List)
            .map((d) => InboundNoteDetail.fromJson(d as Map<String, dynamic>))
            .toList(),
        rejectReason: json['rejectReason'] as String?,
      );
}
