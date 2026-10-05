// Phòng ban (màn hình Admin > Phòng ban, và danh sách chọn khi tạo nhân viên).
class Department {
  final String departmentCode;
  final String departmentName;
  final String? managerName;
  final String? description;
  final bool isActive;

  Department({
    required this.departmentCode,
    required this.departmentName,
    this.managerName,
    this.description,
    required this.isActive,
  });

  factory Department.fromJson(Map<String, dynamic> json) => Department(
        departmentCode: json['departmentCode'] as String,
        departmentName: (json['departmentName'] as String?) ?? '',
        managerName: json['managerName'] as String?,
        description: json['description'] as String?,
        isActive: json['isActive'] as bool? ?? true,
      );
}
