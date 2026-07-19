import 'note_status.dart';

class StockCheckDetail {
  final String productId;
  final int systemQty;
  final int actualQty;
  final String note;

  StockCheckDetail({
    required this.productId,
    required this.systemQty,
    required this.actualQty,
    this.note = '',
  });

  int get difference => actualQty - systemQty;

  factory StockCheckDetail.fromJson(Map<String, dynamic> json) {
    return StockCheckDetail(
      productId: json['productId'],
      systemQty: json['systemQty'],
      actualQty: json['actualQty'],
      note: json['note'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'productId': productId,
      'systemQty': systemQty,
      'actualQty': actualQty,
      'note': note,
    };
  }
}

class StockCheckNoteModel {
  final String id;
  final String code;
  final DateTime checkDate;
  final String createdBy;
  final String status;
  final List<StockCheckDetail> details;

  StockCheckNoteModel({
    required this.id,
    required this.code,
    required this.checkDate,
    required this.createdBy,
    this.status = NoteStatus.pending,
    required this.details,
  });

  StockCheckNoteModel copyWith({
    String? code,
    DateTime? checkDate,
    String? status,
    List<StockCheckDetail>? details,
  }) {
    return StockCheckNoteModel(
      id: id,
      code: code ?? this.code,
      checkDate: checkDate ?? this.checkDate,
      createdBy: createdBy,
      status: status ?? this.status,
      details: details ?? this.details,
    );
  }

  factory StockCheckNoteModel.fromJson(Map<String, dynamic> json) {
    return StockCheckNoteModel(
      id: json['id'],
      code: json['code'],
      checkDate: DateTime.parse(json['checkDate']),
      createdBy: json['createdBy'],
      status: json['status'],
      details: (json['details'] as List<dynamic>)
          .map((e) => StockCheckDetail.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'code': code,
      'checkDate': checkDate.toIso8601String(),
      'createdBy': createdBy,
      'status': status,
      'details': details.map((e) => e.toJson()).toList(),
    };
  }
}
