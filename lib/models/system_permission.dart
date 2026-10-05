class SystemPermission {
  final String permissionCode;
  final String permissionName;
  final String module;
  final String? description;
  final bool isActive;

  const SystemPermission({
    required this.permissionCode,
    required this.permissionName,
    required this.module,
    this.description,
    required this.isActive,
  });

  factory SystemPermission.fromJson(Map<String, dynamic> json) => SystemPermission(
        permissionCode: json['permissionCode'] as String,
        permissionName: (json['permissionName'] as String?) ?? '',
        module: (json['module'] as String?) ?? '',
        description: json['description'] as String?,
        isActive: (json['isActive'] as bool?) ?? true,
      );
}
