// Một nút trong cây tổ chức (GET /employees/org-tree), lồng nhau theo subordinates.
class OrgTreeNode {
  final String employeeCode;
  final String fullName;
  final String positionName;
  final String departmentName;
  final String employmentStatus;
  final String todayAttendanceStatus;
  final int subordinateCount;
  final List<OrgTreeNode> subordinates;

  OrgTreeNode({
    required this.employeeCode,
    required this.fullName,
    required this.positionName,
    required this.departmentName,
    required this.employmentStatus,
    required this.todayAttendanceStatus,
    required this.subordinateCount,
    required this.subordinates,
  });

  factory OrgTreeNode.fromJson(Map<String, dynamic> json) {
    return OrgTreeNode(
      employeeCode: json['employeeCode'] as String,
      fullName: json['fullName'] as String? ?? '',
      positionName: json['positionName'] as String? ?? '',
      departmentName: json['departmentName'] as String? ?? '',
      employmentStatus: json['employmentStatus'] as String? ?? '',
      todayAttendanceStatus: json['todayAttendanceStatus'] as String? ?? '',
      subordinateCount: (json['subordinateCount'] as num?)?.toInt() ?? 0,
      subordinates: ((json['subordinates'] as List?) ?? const [])
          .map((e) => OrgTreeNode.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}
