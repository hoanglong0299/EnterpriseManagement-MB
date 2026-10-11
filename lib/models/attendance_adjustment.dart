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
  // Bước xử lý (HR). status: Pending (chờ Manager), PendingHr (chờ xử lý), Approved (đã áp dụng), Rejected.
  final String? processedByName;
  final DateTime? processedAt;
  final String? rejectionReason;
  final String employeeCode;
  final String employeeName;

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
    this.processedByName,
    this.processedAt,
    this.rejectionReason,
    this.employeeCode = '',
    this.employeeName = '',
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
      processedByName: json['processedByName'] as String?,
      processedAt: _date(json['processedAt']),
      rejectionReason: json['rejectionReason'] as String?,
      employeeCode: (json['employeeCode'] as String?) ?? '',
      employeeName: (json['employeeName'] as String?) ?? '',
    );
  }
}
