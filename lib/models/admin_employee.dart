// Hồ sơ nhân viên đầy đủ (màn hình Admin > Quản lý nhân viên).
class AdminEmployee {
  final String employeeCode;
  final String firstName;
  final String lastName;
  final String fullName;
  final String email;
  final String? phone;
  final String? address;
  final DateTime? dateOfBirth;
  final String? gender;
  final String departmentCode;
  final String departmentName;
  final String positionCode;
  final String positionName;
  final String? managerCode;
  final String? managerName;
  final String employmentStatus;
  final DateTime? hireDate;
  // Tài khoản đăng nhập gắn 1-1 với hồ sơ.
  final String username;
  final List<String> roleCodes;
  final List<String> roleNames;
  final bool isAccountActive;
  final DateTime? lastLoginAt;

  AdminEmployee({
    required this.employeeCode,
    required this.firstName,
    required this.lastName,
    required this.fullName,
    this.email = '',
    this.phone,
    this.address,
    this.dateOfBirth,
    this.gender,
    required this.departmentCode,
    required this.departmentName,
    required this.positionCode,
    required this.positionName,
    this.managerCode,
    this.managerName,
    required this.employmentStatus,
    this.hireDate,
    this.username = '',
    this.roleCodes = const [],
    this.roleNames = const [],
    this.isAccountActive = true,
    this.lastLoginAt,
  });

  // Còn làm việc: mọi trạng thái trừ nghỉ việc.
  bool get isActive => employmentStatus != 'Resigned' && employmentStatus != 'Terminated';

  static List<String> _strings(Object? v) => ((v as List?) ?? const []).map((e) => e.toString()).toList();

  factory AdminEmployee.fromJson(Map<String, dynamic> json) {
    DateTime? date(String key) {
      final v = json[key] as String?;
      return v == null ? null : DateTime.tryParse(v);
    }

    return AdminEmployee(
      employeeCode: json['employeeCode'] as String,
      firstName: (json['firstName'] as String?) ?? '',
      lastName: (json['lastName'] as String?) ?? '',
      fullName: (json['fullName'] as String?) ?? '',
      email: (json['email'] as String?) ?? '',
      phone: json['phone'] as String?,
      address: json['address'] as String?,
      dateOfBirth: date('dateOfBirth'),
      gender: json['gender'] as String?,
      departmentCode: (json['departmentCode'] as String?) ?? '',
      departmentName: (json['departmentName'] as String?) ?? '',
      positionCode: (json['positionCode'] as String?) ?? '',
      positionName: (json['positionName'] as String?) ?? '',
      managerCode: json['managerCode'] as String?,
      managerName: json['managerName'] as String?,
      employmentStatus: (json['employmentStatus'] as String?) ?? '',
      hireDate: date('hireDate'),
      username: (json['username'] as String?) ?? '',
      roleCodes: _strings(json['roleCodes']),
      roleNames: _strings(json['roleNames']),
      isAccountActive: json['isAccountActive'] as bool? ?? true,
      lastLoginAt: date('lastLoginAt'),
    );
  }
}

// Vai trò (chỉ dùng để chọn khi tạo/sửa nhân viên).
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

// Mật khẩu tạm vừa sinh (khi tạo nhân viên hoặc đặt lại): chỉ hiện một lần.
class AdminCredential {
  final String username;
  final String password;
  final bool isReset;

  AdminCredential({required this.username, required this.password, required this.isReset});
}

// Kết quả POST /employees.
class CreateEmployeeResult {
  final AdminEmployee employee;
  final String generatedPassword;

  CreateEmployeeResult({required this.employee, required this.generatedPassword});

  factory CreateEmployeeResult.fromJson(Map<String, dynamic> json) => CreateEmployeeResult(
        employee: AdminEmployee.fromJson(json['employee'] as Map<String, dynamic>),
        generatedPassword: json['generatedPassword'] as String,
      );
}
