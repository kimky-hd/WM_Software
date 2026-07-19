class UnitModel {
  final String id;
  final String unitName;
  final double conversionFactor;

  UnitModel({
    required this.id,
    required this.unitName,
    required this.conversionFactor,
  });

  factory UnitModel.fromJson(Map<String, dynamic> json) {
    return UnitModel(
      id: json['id'],
      unitName: json['unitName'],
      conversionFactor: (json['conversionFactor'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'unitName': unitName,
      'conversionFactor': conversionFactor,
    };
  }
}
