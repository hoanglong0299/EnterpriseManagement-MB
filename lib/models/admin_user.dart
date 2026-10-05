// Tài khoản đăng nhập (màn hình Admin > Tài khoản).
class AdminUser {
  final String username;
  final String email;
  final String? employeeCode;
  final String? employeeName;
  final List<String> roles;
  final bool isActive;
  final DateTime? lastLoginAt;

  AdminUser({
    required this.username,
    required this.email,
    this.employeeCode,
    this.employeeName,
    required this.roles,
    required this.isActive,
    this.lastLoginAt,
  });

  factory AdminUser.fromJson(Map<String, dynamic> json) {
    final last = json['lastLoginAt'] as String?;
    return AdminUser(
      username: json['username'] as String,
      email: (json['email'] as String?) ?? '',
      employeeCode: json['employeeCode'] as String?,
      employeeName: json['employeeName'] as String?,
      roles: ((json['roles'] as List?) ?? const []).map((e) => e.toString()).toList(),
      isActive: json['isActive'] as bool? ?? true,
      lastLoginAt: last == null ? null : DateTime.parse(last),
    );
  }
}

// Vai trò (chỉ dùng để chọn khi tạo tài khoản).
class AdminRole {
  final String roleCode;
  final String roleName;
  final bool isActive;

  AdminRole({required this.roleCode, required this.roleName, required this.isActive});

  factory AdminRole.fromJson(Map<String, dynamic> json) => AdminRole(
        roleCode: json['roleCode'] as String,
        roleName: (json['roleName'] as String?) ?? json['roleCode'] as String,
        isActive: json['isActive'] as bool? ?? true,
      );
}

// Kết quả tạo tài khoản / đặt lại mật khẩu: mật khẩu tạm chỉ hiện một lần.
class AdminCredential {
  final String username;
  final String password;
  final bool isReset;

  AdminCredential({required this.username, required this.password, required this.isReset});
}
