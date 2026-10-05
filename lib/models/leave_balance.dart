class LeaveBalance {
  final String leaveTypeCode;
  final String leaveTypeName;
  final String unit;
  final double allocatedTime;
  final double usedTime;
  final double remainingTime;
  final int? year;
  // Chỉ có với loại reset theo tháng (nghỉ ngắn).
  final int? month;

  LeaveBalance({
    required this.leaveTypeCode,
    required this.leaveTypeName,
    required this.unit,
    required this.allocatedTime,
    required this.usedTime,
    required this.remainingTime,
    this.year,
    this.month,
  });

  factory LeaveBalance.fromJson(Map<String, dynamic> json) {
    return LeaveBalance(
      leaveTypeCode: json['leaveTypeCode'] as String,
      leaveTypeName: json['leaveTypeName'] as String,
      unit: json['unit'] as String,
      allocatedTime: (json['allocatedTime'] as num).toDouble(),
      usedTime: (json['usedTime'] as num).toDouble(),
      remainingTime: (json['remainingTime'] as num).toDouble(),
      year: json['year'] as int?,
      month: json['month'] as int?,
    );
  }

  // "Tháng 10/2026" hoặc "Năm 2026".
  String get periodLabel => month != null ? 'Tháng $month/$year' : 'Năm $year';
}
