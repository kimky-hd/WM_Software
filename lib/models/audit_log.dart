/// Nhật ký hoạt động (Audit Log) - ai duyệt/từ chối/huỷ gì, thời điểm nào.
class AuditLogEntry {
  final String id;
  final DateTime timestamp;
  final String actorId;
  final String actorName;
  final String action;
  final String targetCode;
  final String? note;

  const AuditLogEntry({
    required this.id,
    required this.timestamp,
    required this.actorId,
    required this.actorName,
    required this.action,
    required this.targetCode,
    this.note,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'timestamp': timestamp.toIso8601String(),
        'actorId': actorId,
        'actorName': actorName,
        'action': action,
        'targetCode': targetCode,
        'note': note,
      };

  factory AuditLogEntry.fromJson(Map<String, dynamic> json) => AuditLogEntry(
        id: json['id'] as String,
        timestamp: DateTime.parse(json['timestamp'] as String),
        actorId: json['actorId'] as String,
        actorName: json['actorName'] as String,
        action: json['action'] as String,
        targetCode: json['targetCode'] as String,
        note: json['note'] as String?,
      );
}
