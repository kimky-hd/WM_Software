/// Đơn vị tính & hệ số quy đổi về đơn vị gốc (VD: 1 bao = 25kg).
class UnitOfMeasure {
  final String id;
  final String name;
  final double conversionFactor;

  const UnitOfMeasure({
    required this.id,
    required this.name,
    required this.conversionFactor,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'conversionFactor': conversionFactor,
      };

  factory UnitOfMeasure.fromJson(Map<String, dynamic> json) => UnitOfMeasure(
        id: json['id'] as String,
        name: json['name'] as String,
        conversionFactor: (json['conversionFactor'] as num).toDouble(),
      );
}
