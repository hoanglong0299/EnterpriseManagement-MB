DateTime? _date(Map<String, dynamic> json, String key) {
  final v = json[key] as String?;
  return v == null ? null : DateTime.tryParse(v);
}

// Bản ghi chấm công cả phòng (GET /attendance/department/{code}).
class ManagerAttendanceRecord {
  final String employeeCode;
  final String employeeName;
  final DateTime attendanceDate;
  final DateTime? checkInTime;
  final DateTime? checkOutTime;
  final double? workingHours;
  final String status;

  ManagerAttendanceRecord({
    required this.employeeCode,
    required this.employeeName,
    required this.attendanceDate,
    this.checkInTime,
    this.checkOutTime,
    this.workingHours,
    required this.status,
  });

  factory ManagerAttendanceRecord.fromJson(Map<String, dynamic> json) {
    return ManagerAttendanceRecord(
      employeeCode: json['employeeCode'] as String? ?? '',
      employeeName: json['employeeName'] as String? ?? '',
      attendanceDate: _date(json, 'attendanceDate') ?? DateTime.now(),
      checkInTime: _date(json, 'checkInTime'),
      checkOutTime: _date(json, 'checkOutTime'),
      workingHours: (json['workingHours'] as num?)?.toDouble(),
      status: json['status'] as String? ?? '',
    );
  }
}

// Yêu cầu điều chỉnh công đang chờ duyệt (GET /attendance/adjustments/pending).
class ManagerAttendanceAdjustment {
  final int id;
  final String employeeCode;
  final String employeeName;
  final DateTime attendanceDate;
  final String reason;
  final DateTime? oldCheckInTime;
  final DateTime? newCheckInTime;
  final DateTime? oldCheckOutTime;
  final DateTime? newCheckOutTime;
  final String status;

  ManagerAttendanceAdjustment({
    required this.id,
    required this.employeeCode,
    required this.employeeName,
    required this.attendanceDate,
    required this.reason,
    this.oldCheckInTime,
    this.newCheckInTime,
    this.oldCheckOutTime,
    this.newCheckOutTime,
    required this.status,
  });

  factory ManagerAttendanceAdjustment.fromJson(Map<String, dynamic> json) {
    return ManagerAttendanceAdjustment(
      id: (json['id'] as num).toInt(),
      employeeCode: json['employeeCode'] as String? ?? '',
      employeeName: json['employeeName'] as String? ?? '',
      attendanceDate: _date(json, 'attendanceDate') ?? DateTime.now(),
      reason: json['reason'] as String? ?? '',
      oldCheckInTime: _date(json, 'oldCheckInTime'),
      newCheckInTime: _date(json, 'newCheckInTime'),
      oldCheckOutTime: _date(json, 'oldCheckOutTime'),
      newCheckOutTime: _date(json, 'newCheckOutTime'),
      status: json['status'] as String? ?? '',
    );
  }
}
