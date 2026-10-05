// Chức vụ (màn hình Admin > Chức vụ, và danh sách chọn khi tạo nhân viên).
class Position {
  final String positionCode;
  final String positionName;
  final String? description;
  final bool isActive;
  final double? standardSalary;

  Position({
    required this.positionCode,
    required this.positionName,
    this.description,
    required this.isActive,
    this.standardSalary,
  });

  factory Position.fromJson(Map<String, dynamic> json) => Position(
        positionCode: json['positionCode'] as String,
        positionName: (json['positionName'] as String?) ?? '',
        description: json['description'] as String?,
        isActive: json['isActive'] as bool? ?? true,
        standardSalary: (json['standardSalary'] as num?)?.toDouble(),
      );
}
