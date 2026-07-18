import 'enums.dart';

/// Dòng chi tiết kiểm kê - so sánh tồn hệ thống với tồn thực tế.
class StockCheckDetail {
  final String productId;
  final double systemQty;
  final double actualQty;

  const StockCheckDetail({
    required this.productId,
    required this.systemQty,
    required this.actualQty,
  });

  double get difference => actualQty - systemQty;

  Map<String, dynamic> toJson() => {
        'productId': productId,
        'systemQty': systemQty,
        'actualQty': actualQty,
      };

  factory StockCheckDetail.fromJson(Map<String, dynamic> json) => StockCheckDetail(
        productId: json['productId'] as String,
        systemQty: (json['systemQty'] as num).toDouble(),
        actualQty: (json['actualQty'] as num).toDouble(),
      );
}

class StockCheckNote {
  final String id;
  final String code;
  final DateTime checkDate;
  final String performedBy;
  final String? approvedBy;
  final DocumentStatus status;
  final List<StockCheckDetail> details;

  const StockCheckNote({
    required this.id,
    required this.code,
    required this.checkDate,
    required this.performedBy,
    this.approvedBy,
    required this.status,
    required this.details,
  });

  StockCheckNote copyWith({DocumentStatus? status, String? approvedBy}) => StockCheckNote(
        id: id,
        code: code,
        checkDate: checkDate,
        performedBy: performedBy,
        approvedBy: approvedBy ?? this.approvedBy,
        status: status ?? this.status,
        details: details,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'code': code,
        'checkDate': checkDate.toIso8601String(),
        'performedBy': performedBy,
        'approvedBy': approvedBy,
        'status': status.name,
        'details': details.map((d) => d.toJson()).toList(),
      };

  factory StockCheckNote.fromJson(Map<String, dynamic> json) => StockCheckNote(
        id: json['id'] as String,
        code: json['code'] as String,
        checkDate: DateTime.parse(json['checkDate'] as String),
        performedBy: json['performedBy'] as String,
        approvedBy: json['approvedBy'] as String?,
        status: DocumentStatus.values.byName(json['status'] as String),
        details: (json['details'] as List)
            .map((d) => StockCheckDetail.fromJson(d as Map<String, dynamic>))
            .toList(),
      );
}
