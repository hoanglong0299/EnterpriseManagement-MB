class LeaveRequest {
  final int id;
  final String leaveTypeCode;
  final String leaveTypeName;
  final DateTime startDate;
  final DateTime endDate;
  final String? session;
  final String unit;
  final double totalTime;
  final String? reason;
  final String status;
  final String? approverName;
  final String? rejectionReason;

  LeaveRequest({
    required this.id,
    required this.leaveTypeCode,
    required this.leaveTypeName,
    required this.startDate,
    required this.endDate,
    this.session,
    required this.unit,
    required this.totalTime,
    this.reason,
    required this.status,
    this.approverName,
    this.rejectionReason,
  });

  factory LeaveRequest.fromJson(Map<String, dynamic> json) {
    return LeaveRequest(
      id: json['id'] as int,
      leaveTypeCode: json['leaveTypeCode'] as String,
      leaveTypeName: json['leaveTypeName'] as String,
      startDate: DateTime.parse(json['startDate'] as String),
      endDate: DateTime.parse(json['endDate'] as String),
      session: json['session'] as String?,
      unit: json['unit'] as String,
      totalTime: (json['totalTime'] as num).toDouble(),
      reason: json['reason'] as String?,
      status: json['status'] as String,
      approverName: json['approverName'] as String?,
      rejectionReason: json['rejectionReason'] as String?,
    );
  }
}
