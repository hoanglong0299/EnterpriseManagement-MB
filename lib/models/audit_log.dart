// Một dòng nhật ký thao tác (GET /audit-logs). createdAt do backend lưu sẵn theo giờ Việt Nam (không kèm múi giờ).
class AuditLog {
  final int id;
  final DateTime createdAt;
  final String? username;
  final String module;
  final String action;
  final String? target;
  final String? ipAddress;

  const AuditLog({
    required this.id,
    required this.createdAt,
    this.username,
    required this.module,
    required this.action,
    this.target,
    this.ipAddress,
  });

  factory AuditLog.fromJson(Map<String, dynamic> json) => AuditLog(
        id: (json['id'] as num).toInt(),
        createdAt: DateTime.parse(json['createdAt'] as String),
        username: json['username'] as String?,
        module: (json['module'] as String?) ?? '',
        action: (json['action'] as String?) ?? '',
        target: json['target'] as String?,
        ipAddress: json['ipAddress'] as String?,
      );
}
