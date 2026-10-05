// Hồ sơ nhân viên đầy đủ (màn hình Admin > Quản lý nhân viên).
class AdminEmployee {
  final String employeeCode;
  final String firstName;
  final String lastName;
  final String fullName;
  final String? email;
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

  AdminEmployee({
    required this.employeeCode,
    required this.firstName,
    required this.lastName,
    required this.fullName,
    this.email,
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
  });

  bool get isActive => employmentStatus == 'Active';

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
      email: json['email'] as String?,
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
    );
  }
}
