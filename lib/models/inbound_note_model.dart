import 'note_status.dart';

class InboundNoteDetail {
  final String productId;
  final String batchCode;
  final DateTime manufactureDate;
  final DateTime expiryDate;
  final int quantity;
  final String unit;

  InboundNoteDetail({
    required this.productId,
    required this.batchCode,
    required this.manufactureDate,
    required this.expiryDate,
    required this.quantity,
    required this.unit,
  });

  factory InboundNoteDetail.fromJson(Map<String, dynamic> json) {
    return InboundNoteDetail(
      productId: json['productId'],
      batchCode: json['batchCode'],
      manufactureDate: DateTime.parse(json['manufactureDate']),
      expiryDate: DateTime.parse(json['expiryDate']),
      quantity: json['quantity'],
      unit: json['unit'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'productId': productId,
      'batchCode': batchCode,
      'manufactureDate': manufactureDate.toIso8601String(),
      'expiryDate': expiryDate.toIso8601String(),
      'quantity': quantity,
      'unit': unit,
    };
  }
}

class InboundNoteModel {
  final String id;
  final String code;
  final DateTime createdDate;
  final String createdBy;
  final String supplierId;
  final String status;
  final List<InboundNoteDetail> details;

  InboundNoteModel({
    required this.id,
    required this.code,
    required this.createdDate,
    required this.createdBy,
    required this.supplierId,
    this.status = NoteStatus.pending,
    required this.details,
  });

  InboundNoteModel copyWith({
    String? code,
    DateTime? createdDate,
    String? supplierId,
    String? status,
    List<InboundNoteDetail>? details,
  }) {
    return InboundNoteModel(
      id: id,
      code: code ?? this.code,
      createdDate: createdDate ?? this.createdDate,
      createdBy: createdBy,
      supplierId: supplierId ?? this.supplierId,
      status: status ?? this.status,
      details: details ?? this.details,
    );
  }

  factory InboundNoteModel.fromJson(Map<String, dynamic> json) {
    return InboundNoteModel(
      id: json['id'],
      code: json['code'],
      createdDate: DateTime.parse(json['createdDate']),
      createdBy: json['createdBy'],
      supplierId: json['supplierId'],
      status: json['status'],
      details: (json['details'] as List<dynamic>)
          .map((e) => InboundNoteDetail.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'code': code,
      'createdDate': createdDate.toIso8601String(),
      'createdBy': createdBy,
      'supplierId': supplierId,
      'status': status,
      'details': details.map((e) => e.toJson()).toList(),
    };
  }
}
