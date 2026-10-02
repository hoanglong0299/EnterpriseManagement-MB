class LeaveType {
  final String leaveTypeCode;
  final String leaveTypeName;
  final String accrualUnit;
  final bool isPaid;

  LeaveType({
    required this.leaveTypeCode,
    required this.leaveTypeName,
    required this.accrualUnit,
    required this.isPaid,
  });

  factory LeaveType.fromJson(Map<String, dynamic> json) {
    return LeaveType(
      leaveTypeCode: json['leaveTypeCode'] as String,
      leaveTypeName: json['leaveTypeName'] as String,
      accrualUnit: json['accrualUnit'] as String,
      isPaid: json['isPaid'] as bool,
    );
  }
}
