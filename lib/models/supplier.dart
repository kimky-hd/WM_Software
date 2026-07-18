class Supplier {
  final String id;
  final String name;
  final String contact;
  final String taxCode;

  const Supplier({
    required this.id,
    required this.name,
    required this.contact,
    required this.taxCode,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'contact': contact,
        'taxCode': taxCode,
      };

  factory Supplier.fromJson(Map<String, dynamic> json) => Supplier(
        id: json['id'] as String,
        name: json['name'] as String,
        contact: json['contact'] as String,
        taxCode: json['taxCode'] as String,
      );
}
