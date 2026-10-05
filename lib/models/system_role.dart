class SystemRole {
  final String roleCode;
  final String roleName;
  final String? description;
  final List<String> permissions;
  final bool isActive;

  const SystemRole({
    required this.roleCode,
    required this.roleName,
    this.description,
    required this.permissions,
    required this.isActive,
  });

  factory SystemRole.fromJson(Map<String, dynamic> json) => SystemRole(
        roleCode: json['roleCode'] as String,
        roleName: (json['roleName'] as String?) ?? '',
        description: json['description'] as String?,
        permissions: ((json['permissions'] as List?) ?? const []).map((e) => e as String).toList(),
        isActive: (json['isActive'] as bool?) ?? true,
      );
}
