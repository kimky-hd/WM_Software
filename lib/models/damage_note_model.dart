import 'note_status.dart';

/// Loại phiếu hàng hỏng/hết hạn.
class DamageType {
  static const String damaged = 'DAMAGED';
  static const String expired = 'EXPIRED';

  static String label(String type) {
    switch (type) {
      case damaged:
        return 'Hàng hỏng';
      case expired:
        return 'Hết hạn';
      default:
        return type;
    }
  }
}

class DamageNoteModel {
  final String id;
  final String code;
  final DateTime createdDate;
  final String createdBy;
  final String batchId;
  final String productId;
  final int quantity;
  final String type; // DamageType.damaged | DamageType.expired
  final String reason;
  final String status;

  DamageNoteModel({
    required this.id,
    required this.code,
    required this.createdDate,
    required this.createdBy,
    required this.batchId,
    required this.productId,
    required this.quantity,
    required this.type,
    required this.reason,
    this.status = NoteStatus.pending,
  });

  DamageNoteModel copyWith({
    String? code,
    DateTime? createdDate,
    String? batchId,
    String? productId,
    int? quantity,
    String? type,
    String? reason,
    String? status,
  }) {
    return DamageNoteModel(
      id: id,
      code: code ?? this.code,
      createdDate: createdDate ?? this.createdDate,
      createdBy: createdBy,
      batchId: batchId ?? this.batchId,
      productId: productId ?? this.productId,
      quantity: quantity ?? this.quantity,
      type: type ?? this.type,
      reason: reason ?? this.reason,
      status: status ?? this.status,
    );
  }

  factory DamageNoteModel.fromJson(Map<String, dynamic> json) {
    return DamageNoteModel(
      id: json['id'],
      code: json['code'],
      createdDate: DateTime.parse(json['createdDate']),
      createdBy: json['createdBy'],
      batchId: json['batchId'],
      productId: json['productId'],
      quantity: json['quantity'],
      type: json['type'],
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
      'batchId': batchId,
      'productId': productId,
      'quantity': quantity,
      'type': type,
      'reason': reason,
      'status': status,
    };
  }
}
