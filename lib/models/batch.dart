/// Lô hàng (Batch/Lot) - gắn khi nhập kho, theo dõi HSD để xuất theo FEFO.
class Batch {
  final String id;
  final String productId;
  final String batchCode;
  final DateTime manufactureDate;
  final DateTime expiryDate;
  final double quantityIn;
  final double quantityRemaining;

  const Batch({
    required this.id,
    required this.productId,
    required this.batchCode,
    required this.manufactureDate,
    required this.expiryDate,
    required this.quantityIn,
    required this.quantityRemaining,
  });

  Batch copyWith({double? quantityRemaining}) => Batch(
        id: id,
        productId: productId,
        batchCode: batchCode,
        manufactureDate: manufactureDate,
        expiryDate: expiryDate,
        quantityIn: quantityIn,
        quantityRemaining: quantityRemaining ?? this.quantityRemaining,
      );

  bool get isExpired => expiryDate.isBefore(DateTime.now());

  int get daysToExpiry => expiryDate.difference(DateTime.now()).inDays;

  Map<String, dynamic> toJson() => {
        'id': id,
        'productId': productId,
        'batchCode': batchCode,
        'manufactureDate': manufactureDate.toIso8601String(),
        'expiryDate': expiryDate.toIso8601String(),
        'quantityIn': quantityIn,
        'quantityRemaining': quantityRemaining,
      };

  factory Batch.fromJson(Map<String, dynamic> json) => Batch(
        id: json['id'] as String,
        productId: json['productId'] as String,
        batchCode: json['batchCode'] as String,
        manufactureDate: DateTime.parse(json['manufactureDate'] as String),
        expiryDate: DateTime.parse(json['expiryDate'] as String),
        quantityIn: (json['quantityIn'] as num).toDouble(),
        quantityRemaining: (json['quantityRemaining'] as num).toDouble(),
      );
}
