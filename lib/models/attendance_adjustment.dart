// Yêu cầu điều chỉnh công của nhân viên (AttendanceAdjustmentDto ở backend).
class AttendanceAdjustment {
  final int id;
  final String attendanceDate;
  final String reason;
  final DateTime? oldCheckInTime;
  final DateTime? newCheckInTime;
  final DateTime? oldCheckOutTime;
  final DateTime? newCheckOutTime;
  final String status;
  final String? approverName;
  final DateTime? approvedAt;

  AttendanceAdjustment({
    required this.id,
    required this.attendanceDate,
    required this.reason,
    this.oldCheckInTime,
    this.newCheckInTime,
    this.oldCheckOutTime,
    this.newCheckOutTime,
    required this.status,
    this.approverName,
    this.approvedAt,
  });

  static DateTime? _date(dynamic v) => v == null ? null : DateTime.parse(v as String);

  factory AttendanceAdjustment.fromJson(Map<String, dynamic> json) {
    return AttendanceAdjustment(
      id: (json['id'] as num).toInt(),
      attendanceDate: json['attendanceDate'] as String,
      reason: (json['reason'] as String?) ?? '',
      oldCheckInTime: _date(json['oldCheckInTime']),
      newCheckInTime: _date(json['newCheckInTime']),
      oldCheckOutTime: _date(json['oldCheckOutTime']),
      newCheckOutTime: _date(json['newCheckOutTime']),
      status: json['status'] as String,
      approverName: json['approverName'] as String?,
      approvedAt: _date(json['approvedAt']),
    );
  }
}
