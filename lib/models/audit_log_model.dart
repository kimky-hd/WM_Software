class AuditLogModel {
  final String id;
  final String userName;
  final String action;
  final DateTime timestamp;

  AuditLogModel({
    required this.id,
    required this.userName,
    required this.action,
    required this.timestamp,
  });

  factory AuditLogModel.fromJson(Map<String, dynamic> json) {
    return AuditLogModel(
      id: json['id'],
      userName: json['userName'],
      action: json['action'],
      timestamp: DateTime.parse(json['timestamp']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userName': userName,
      'action': action,
      'timestamp': timestamp.toIso8601String(),
    };
  }
}
