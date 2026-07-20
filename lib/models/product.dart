/// Danh mục sản phẩm dùng chung (ngũ cốc/hạt/đồ khô...).
class Product {
  final String id;
  final String code;
  final String name;
  final String category;
  final String baseUnitId;
  final double minStock;
  final int defaultExpiryDays;

  const Product({
    required this.id,
    required this.code,
    required this.name,
    required this.category,
    required this.baseUnitId,
    required this.minStock,
    required this.defaultExpiryDays,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'code': code,
        'name': name,
        'category': category,
        'baseUnitId': baseUnitId,
        'minStock': minStock,
        'defaultExpiryDays': defaultExpiryDays,
      };

  factory Product.fromJson(Map<String, dynamic> json) => Product(
        id: json['id'] as String,
        code: json['code'] as String,
        name: json['name'] as String,
        category: json['category'] as String,
        baseUnitId: json['baseUnitId'] as String,
        minStock: (json['minStock'] as num).toDouble(),
        defaultExpiryDays: json['defaultExpiryDays'] as int,
      );
}
