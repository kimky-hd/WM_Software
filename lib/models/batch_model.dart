class BatchModel {
  final String id;
  final String productId;
  final String batchCode;
  final DateTime manufactureDate;
  final DateTime expiryDate;
  final int quantityImported;
  final int quantityRemaining;

  BatchModel({
    required this.id,
    required this.productId,
    required this.batchCode,
    required this.manufactureDate,
    required this.expiryDate,
    required this.quantityImported,
    required this.quantityRemaining,
  });

  BatchModel copyWith({
    String? id,
    String? productId,
    String? batchCode,
    DateTime? manufactureDate,
    DateTime? expiryDate,
    int? quantityImported,
    int? quantityRemaining,
  }) {
    return BatchModel(
      id: id ?? this.id,
      productId: productId ?? this.productId,
      batchCode: batchCode ?? this.batchCode,
      manufactureDate: manufactureDate ?? this.manufactureDate,
      expiryDate: expiryDate ?? this.expiryDate,
      quantityImported: quantityImported ?? this.quantityImported,
      quantityRemaining: quantityRemaining ?? this.quantityRemaining,
    );
  }

  factory BatchModel.fromJson(Map<String, dynamic> json) {
    return BatchModel(
      id: json['id'],
      productId: json['productId'],
      batchCode: json['batchCode'],
      manufactureDate: DateTime.parse(json['manufactureDate']),
      expiryDate: DateTime.parse(json['expiryDate']),
      quantityImported: json['quantityImported'],
      quantityRemaining: json['quantityRemaining'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'productId': productId,
      'batchCode': batchCode,
      'manufactureDate': manufactureDate.toIso8601String(),
      'expiryDate': expiryDate.toIso8601String(),
      'quantityImported': quantityImported,
      'quantityRemaining': quantityRemaining,
    };
  }
}
