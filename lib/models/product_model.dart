class ProductModel {
  final String id;
  final String productCode;
  final String name;
  final String category;
  final String unit;
  final int minStockLevel;

  ProductModel({
    required this.id,
    required this.productCode,
    required this.name,
    required this.category,
    required this.unit,
    required this.minStockLevel,
  });

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    return ProductModel(
      id: json['id'],
      productCode: json['productCode'],
      name: json['name'],
      category: json['category'],
      unit: json['unit'],
      minStockLevel: json['minStockLevel'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'productCode': productCode,
      'name': name,
      'category': category,
      'unit': unit,
      'minStockLevel': minStockLevel,
    };
  }
}
