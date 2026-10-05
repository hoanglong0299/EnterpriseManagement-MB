class LeaveType {
  final String leaveTypeCode;
  final String leaveTypeName;
  final String accrualUnit;
  final bool isPaid;
  // MonthlyReset = nghỉ ngắn (chọn khung 30 phút trong hôm nay); loại khác chọn ngày + buổi.
  final String accrualPeriod;
  final String? description;
  final bool isActive;

  LeaveType({
    required this.leaveTypeCode,
    required this.leaveTypeName,
    required this.accrualUnit,
    required this.isPaid,
    this.accrualPeriod = '',
    this.description,
    this.isActive = true,
  });

  bool get isShortLeave => accrualPeriod == 'MonthlyReset';

  factory LeaveType.fromJson(Map<String, dynamic> json) {
    return LeaveType(
      leaveTypeCode: json['leaveTypeCode'] as String,
      leaveTypeName: json['leaveTypeName'] as String,
      accrualUnit: json['accrualUnit'] as String,
      isPaid: json['isPaid'] as bool,
      accrualPeriod: (json['accrualPeriod'] as String?) ?? '',
      description: json['description'] as String?,
      isActive: (json['isActive'] as bool?) ?? true,
    );
  }
}
