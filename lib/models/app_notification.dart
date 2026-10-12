// Một thông báo trong hộp thông báo (khớp NotificationDto của backend).
class AppNotification {
  final int id;
  final String type;
  final String title;
  final String body;
  final String? route;
  final int? refId;
  bool isRead;
  final DateTime createdAt;

  AppNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    this.route,
    this.refId,
    required this.isRead,
    required this.createdAt,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: (json['id'] as num).toInt(),
      type: (json['type'] ?? '') as String,
      title: (json['title'] ?? '') as String,
      body: (json['body'] ?? '') as String,
      route: json['route'] as String?,
      refId: (json['refId'] as num?)?.toInt(),
      isRead: json['isRead'] == true,
      createdAt: DateTime.tryParse((json['createdAt'] ?? '') as String) ?? DateTime.now(),
    );
  }
}
