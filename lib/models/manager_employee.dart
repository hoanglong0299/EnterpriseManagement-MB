// Nhân viên cấp dưới của quản lý (GET /employees/team/{code}/all), đủ field như web.
class ManagerEmployee {
  final String employeeCode;
  final String fullName;
  final String? email;
  final String? phone;
  final String? address;
  final DateTime? dateOfBirth;
  final String? gender;
  final String departmentCode;
  final String departmentName;
  final String positionName;
  final String? managerName;
  final String employmentStatus;
  final DateTime? hireDate;

  ManagerEmployee({
    required this.employeeCode,
    required this.fullName,
    this.email,
    this.phone,
    this.address,
    this.dateOfBirth,
    this.gender,
    required this.departmentCode,
    required this.departmentName,
    required this.positionName,
    this.managerName,
    required this.employmentStatus,
    this.hireDate,
  });

  bool get isActive => employmentStatus == 'Active';

  String get genderLabel {
    switch (gender) {
      case null:
      case '':
        return '--';
      case 'Male':
        return 'Nam';
      case 'Female':
        return 'Nữ';
      default:
        return 'Khác';
    }
  }

  factory ManagerEmployee.fromJson(Map<String, dynamic> json) {
    DateTime? d(String key) {
      final v = json[key] as String?;
      return v == null ? null : DateTime.tryParse(v);
    }

    return ManagerEmployee(
      employeeCode: json['employeeCode'] as String,
      fullName: json['fullName'] as String? ?? '',
      email: json['email'] as String?,
      phone: json['phone'] as String?,
      address: json['address'] as String?,
      dateOfBirth: d('dateOfBirth'),
      gender: json['gender'] as String?,
      departmentCode: json['departmentCode'] as String? ?? '',
      departmentName: json['departmentName'] as String? ?? '',
      positionName: json['positionName'] as String? ?? '',
      managerName: json['managerName'] as String?,
      employmentStatus: json['employmentStatus'] as String? ?? '',
      hireDate: d('hireDate'),
    );
  }
}
