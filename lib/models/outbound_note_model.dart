import 'note_status.dart';

class OutboundNoteDetail {
  final String productId;
  final String batchId;
  final int quantity;
  final String unit;

  OutboundNoteDetail({
    required this.productId,
    required this.batchId,
    required this.quantity,
    required this.unit,
  });

  factory OutboundNoteDetail.fromJson(Map<String, dynamic> json) {
    return OutboundNoteDetail(
      productId: json['productId'],
      batchId: json['batchId'],
      quantity: json['quantity'],
      unit: json['unit'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'productId': productId,
      'batchId': batchId,
      'quantity': quantity,
      'unit': unit,
    };
  }
}

class OutboundNoteModel {
  final String id;
  final String code;
  final DateTime createdDate;
  final String createdBy;
  final String purpose;
  final String status;
  final List<OutboundNoteDetail> details;

  OutboundNoteModel({
    required this.id,
    required this.code,
    required this.createdDate,
    required this.createdBy,
    required this.purpose,
    this.status = NoteStatus.pending,
    required this.details,
  });

  OutboundNoteModel copyWith({
    String? code,
    DateTime? createdDate,
    String? purpose,
    String? status,
    List<OutboundNoteDetail>? details,
  }) {
    return OutboundNoteModel(
      id: id,
      code: code ?? this.code,
      createdDate: createdDate ?? this.createdDate,
      createdBy: createdBy,
      purpose: purpose ?? this.purpose,
      status: status ?? this.status,
      details: details ?? this.details,
    );
  }

  factory OutboundNoteModel.fromJson(Map<String, dynamic> json) {
    return OutboundNoteModel(
      id: json['id'],
      code: json['code'],
      createdDate: DateTime.parse(json['createdDate']),
      createdBy: json['createdBy'],
      purpose: json['purpose'],
      status: json['status'],
      details: (json['details'] as List<dynamic>)
          .map((e) => OutboundNoteDetail.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'code': code,
      'createdDate': createdDate.toIso8601String(),
      'createdBy': createdBy,
      'purpose': purpose,
      'status': status,
      'details': details.map((e) => e.toJson()).toList(),
    };
  }
}
