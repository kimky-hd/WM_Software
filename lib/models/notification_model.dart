class NotificationModel {
  final String id;
  final String alertType;
  final String content;
  final DateTime createdAt;

  NotificationModel({
    required this.id,
    required this.alertType,
    required this.content,
    required this.createdAt,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'],
      alertType: json['alertType'],
      content: json['content'],
      createdAt: DateTime.parse(json['createdAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'alertType': alertType,
      'content': content,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
