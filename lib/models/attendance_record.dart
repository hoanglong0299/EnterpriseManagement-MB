class AttendanceRecord {
  final String employeeCode;
  final String employeeName;
  final String attendanceDate;
  final DateTime? checkInTime;
  final DateTime? checkOutTime;
  final double? workingHours;
  final String status;
  final bool isHoliday;
  final String? holidayName;
  final int overtimeMinutes;

  // Trạng thái hiệu lực theo buổi (None, OnTime, Late, Absent, OnLeave) và nguồn do backend tính; status ở trên chỉ là tóm tắt cả ngày.
  final String morningStatus;
  final String afternoonStatus;
  final String morningSource;
  final String afternoonSource;
  final String? leaveTypeName;
  final String? morningNote;
  final String? afternoonNote;

  AttendanceRecord({
    required this.employeeCode,
    required this.employeeName,
    required this.attendanceDate,
    this.checkInTime,
    this.checkOutTime,
    this.workingHours,
    required this.status,
    this.isHoliday = false,
    this.holidayName,
    this.overtimeMinutes = 0,
    this.morningStatus = 'None',
    this.afternoonStatus = 'None',
    this.morningSource = 'None',
    this.afternoonSource = 'None',
    this.leaveTypeName,
    this.morningNote,
    this.afternoonNote,
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
      isHoliday: json['isHoliday'] as bool? ?? false,
      holidayName: json['holidayName'] as String?,
      overtimeMinutes: (json['overtimeMinutes'] as num?)?.toInt() ?? 0,
      morningStatus: json['morningStatus'] as String? ?? 'None',
      afternoonStatus: json['afternoonStatus'] as String? ?? 'None',
      morningSource: json['morningSource'] as String? ?? 'None',
      afternoonSource: json['afternoonSource'] as String? ?? 'None',
      leaveTypeName: json['leaveTypeName'] as String?,
      morningNote: json['morningNote'] as String?,
      afternoonNote: json['afternoonNote'] as String?,
    );
  }
}
