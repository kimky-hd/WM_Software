import 'note_status.dart';

class AdjustmentNoteModel {
  final String id;
  final String code;
  final DateTime createdDate;
  final String createdBy;
  final String productId;
  final String? batchId;
  final int adjustQuantity; // âm: giảm tồn, dương: tăng tồn
  final String reason;
  final String status;

  AdjustmentNoteModel({
    required this.id,
    required this.code,
    required this.createdDate,
    required this.createdBy,
    required this.productId,
    this.batchId,
    required this.adjustQuantity,
    required this.reason,
    this.status = NoteStatus.pending,
  });

  AdjustmentNoteModel copyWith({
    String? code,
    DateTime? createdDate,
    String? productId,
    String? batchId,
    int? adjustQuantity,
    String? reason,
    String? status,
  }) {
    return AdjustmentNoteModel(
      id: id,
      code: code ?? this.code,
      createdDate: createdDate ?? this.createdDate,
      createdBy: createdBy,
      productId: productId ?? this.productId,
      batchId: batchId ?? this.batchId,
      adjustQuantity: adjustQuantity ?? this.adjustQuantity,
      reason: reason ?? this.reason,
      status: status ?? this.status,
    );
  }

  factory AdjustmentNoteModel.fromJson(Map<String, dynamic> json) {
    return AdjustmentNoteModel(
      id: json['id'],
      code: json['code'],
      createdDate: DateTime.parse(json['createdDate']),
      createdBy: json['createdBy'],
      productId: json['productId'],
      batchId: json['batchId'],
      adjustQuantity: json['adjustQuantity'],
      reason: json['reason'],
      status: json['status'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'code': code,
      'createdDate': createdDate.toIso8601String(),
      'createdBy': createdBy,
      'productId': productId,
      'batchId': batchId,
      'adjustQuantity': adjustQuantity,
      'reason': reason,
      'status': status,
    };
  }
}
