class AuthSession {
  final String token;
  final String username;
  final String? employeeCode;
  final List<String> roles;
  final List<String> permissions;

  AuthSession({
    required this.token,
    required this.username,
    this.employeeCode,
    required this.roles,
    this.permissions = const [],
  });

  factory AuthSession.fromJson(Map<String, dynamic> json) {
    return AuthSession(
      token: json['token'] as String,
      username: json['username'] as String,
      employeeCode: json['employeeCode'] as String?,
      roles: List<String>.from(json['roles'] as List),
      permissions: List<String>.from((json['permissions'] as List?) ?? const []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'token': token,
      'username': username,
      'employeeCode': employeeCode,
      'roles': roles,
      'permissions': permissions,
    };
  }
}