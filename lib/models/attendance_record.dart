class AttendanceRecord {
  final String employeeCode;
  final String employeeName;
  final String attendanceDate;
  final DateTime? checkInTime;
  final DateTime? checkOutTime;
  final double? workingHours;
  final String status;

  AttendanceRecord({
    required this.employeeCode,
    required this.employeeName,
    required this.attendanceDate,
    this.checkInTime,
    this.checkOutTime,
    this.workingHours,
    required this.status,
  });

  factory AttendanceRecord.fromJson(Map<String, dynamic> json) {
    return AttendanceRecord(
      employeeCode: json['employeeCode'] as String,
      employeeName: json['employeeName'] as String,
      attendanceDate: json['attendanceDate'] as String,
      checkInTime: json['checkInTime'] == null
          ? null
          : DateTime.parse(json['checkInTime'] as String),
      checkOutTime: json['checkOutTime'] == null
          ? null
          : DateTime.parse(json['checkOutTime'] as String),
      workingHours: (json['workingHours'] as num?)?.toDouble(),
      status: json['status'] as String,
    );
  }
}
