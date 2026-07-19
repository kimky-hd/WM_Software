class SupplierModel {
  final String id;
  final String name;
  final String contact;
  final String taxCode;

  SupplierModel({
    required this.id,
    required this.name,
    required this.contact,
    required this.taxCode,
  });

  factory SupplierModel.fromJson(Map<String, dynamic> json) {
    return SupplierModel(
      id: json['id'],
      name: json['name'],
      contact: json['contact'],
      taxCode: json['taxCode'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'contact': contact,
      'taxCode': taxCode,
    };
  }
}
