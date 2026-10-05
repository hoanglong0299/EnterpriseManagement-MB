// Phòng ban (GET /departments) - chỉ xem.
class ManagerDepartment {
  final String departmentCode;
  final String departmentName;
  final String? managerName;
  final String? description;
  final bool isActive;

  ManagerDepartment({
    required this.departmentCode,
    required this.departmentName,
    this.managerName,
    this.description,
    required this.isActive,
  });

  factory ManagerDepartment.fromJson(Map<String, dynamic> json) {
    return ManagerDepartment(
      departmentCode: json['departmentCode'] as String? ?? '',
      departmentName: json['departmentName'] as String? ?? '',
      managerName: json['managerName'] as String?,
      description: json['description'] as String?,
      isActive: json['isActive'] as bool? ?? false,
    );
  }
}

// Chức vụ (GET /positions) - chỉ xem.
class ManagerPosition {
  final String positionCode;
  final String positionName;
  final String? description;
  final bool isActive;

  ManagerPosition({
    required this.positionCode,
    required this.positionName,
    this.description,
    required this.isActive,
  });

  factory ManagerPosition.fromJson(Map<String, dynamic> json) {
    return ManagerPosition(
      positionCode: json['positionCode'] as String? ?? '',
      positionName: json['positionName'] as String? ?? '',
      description: json['description'] as String?,
      isActive: json['isActive'] as bool? ?? false,
    );
  }
}
