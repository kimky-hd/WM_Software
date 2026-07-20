import 'note_status.dart';

class ReturnSupplierNoteModel {
  final String id;
  final String code;
  final DateTime createdDate;
  final String createdBy;
  final String supplierId;
  final String batchId;
  final String productId;
  final int quantity;
  final String reason;
  final String status;

  ReturnSupplierNoteModel({
    required this.id,
    required this.code,
    required this.createdDate,
    required this.createdBy,
    required this.supplierId,
    required this.batchId,
    required this.productId,
    required this.quantity,
    required this.reason,
    this.status = NoteStatus.pending,
  });

  ReturnSupplierNoteModel copyWith({
    String? code,
    DateTime? createdDate,
    String? supplierId,
    String? batchId,
    String? productId,
    int? quantity,
    String? reason,
    String? status,
  }) {
    return ReturnSupplierNoteModel(
      id: id,
      code: code ?? this.code,
      createdDate: createdDate ?? this.createdDate,
      createdBy: createdBy,
      supplierId: supplierId ?? this.supplierId,
      batchId: batchId ?? this.batchId,
      productId: productId ?? this.productId,
      quantity: quantity ?? this.quantity,
      reason: reason ?? this.reason,
      status: status ?? this.status,
    );
  }

  factory ReturnSupplierNoteModel.fromJson(Map<String, dynamic> json) {
    return ReturnSupplierNoteModel(
      id: json['id'],
      code: json['code'],
      createdDate: DateTime.parse(json['createdDate']),
      createdBy: json['createdBy'],
      supplierId: json['supplierId'],
      batchId: json['batchId'],
      productId: json['productId'],
      quantity: json['quantity'],
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
      'supplierId': supplierId,
      'batchId': batchId,
      'productId': productId,
      'quantity': quantity,
      'reason': reason,
      'status': status,
    };
  }
}
