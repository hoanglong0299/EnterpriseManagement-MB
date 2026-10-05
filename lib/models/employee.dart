class Employee {
  final String employeeCode;
  final String fullName;
  final String? email;
  final String? phone;
  final DateTime? dateOfBirth;
  final String departmentName;
  final String positionName;
  final String? address;
  final String? gender;
  final String? managerCode;
  final String? managerName;
  final String? employmentStatus;
  final DateTime? hireDate;
  final String firstName;
  final String lastName;
  final String departmentCode;
  final String positionCode;

  Employee({
    required this.employeeCode,
    required this.fullName,
    this.email,
    this.phone,
    this.dateOfBirth,
    required this.departmentName,
    required this.positionName,
    this.address,
    this.gender,
    this.managerCode,
    this.managerName,
    this.employmentStatus,
    this.hireDate,
    this.firstName = '',
    this.lastName = '',
    this.departmentCode = '',
    this.positionCode = '',
  });

  factory Employee.fromJson(Map<String, dynamic> json) {
    DateTime? date(String key) {
      final raw = json[key] as String?;
      return raw == null ? null : DateTime.parse(raw);
    }

    return Employee(
      employeeCode: json['employeeCode'] as String,
      fullName: json['fullName'] as String,
      email: json['email'] as String?,
      phone: json['phone'] as String?,
      dateOfBirth: date('dateOfBirth'),
      departmentName: json['departmentName'] as String,
      positionName: json['positionName'] as String,
      address: json['address'] as String?,
      gender: json['gender'] as String?,
      managerCode: json['managerCode'] as String?,
      managerName: json['managerName'] as String?,
      employmentStatus: json['employmentStatus'] as String?,
      hireDate: date('hireDate'),
      firstName: (json['firstName'] as String?) ?? '',
      lastName: (json['lastName'] as String?) ?? '',
      departmentCode: (json['departmentCode'] as String?) ?? '',
      positionCode: (json['positionCode'] as String?) ?? '',
    );
  }
}
