class Employee {
  final String employeeCode;
  final String fullName;
  final String? email;
  final String? phone;
  final DateTime? dateOfBirth;
  final String departmentName;
  final String positionName;

  Employee({
    required this.employeeCode,
    required this.fullName,
    this.email,
    this.phone,
    this.dateOfBirth,
    required this.departmentName,
    required this.positionName,
  });

  factory Employee.fromJson(Map<String, dynamic> json) {
    final dob = json['dateOfBirth'] as String?;
    return Employee(
      employeeCode: json['employeeCode'] as String,
      fullName: json['fullName'] as String,
      email: json['email'] as String?,
      phone: json['phone'] as String?,
      dateOfBirth: dob == null ? null : DateTime.parse(dob),
      departmentName: json['departmentName'] as String,
      positionName: json['positionName'] as String,
    );
  }
}
