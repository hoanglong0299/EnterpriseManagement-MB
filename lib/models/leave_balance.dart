class LeaveBalance {
  final String leaveTypeCode;
  final String leaveTypeName;
  final String unit;
  final double allocatedTime;
  final double usedTime;
  final double remainingTime;

  LeaveBalance({
    required this.leaveTypeCode,
    required this.leaveTypeName,
    required this.unit,
    required this.allocatedTime,
    required this.usedTime,
    required this.remainingTime,
  });

  factory LeaveBalance.fromJson(Map<String, dynamic> json) {
    return LeaveBalance(
      leaveTypeCode: json['leaveTypeCode'] as String,
      leaveTypeName: json['leaveTypeName'] as String,
      unit: json['unit'] as String,
      allocatedTime: (json['allocatedTime'] as num).toDouble(),
      usedTime: (json['usedTime'] as num).toDouble(),
      remainingTime: (json['remainingTime'] as num).toDouble(),
    );
  }
}
