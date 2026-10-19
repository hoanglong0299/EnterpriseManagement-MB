// Model cho chấm công theo buổi, ghi chú ngoại lệ (HR) và yêu cầu rút ngắn nghỉ phép. Khớp hợp đồng API của backend.

// Trạng thái một buổi: None, OnTime, Late, Absent, OnLeave. Nguồn: None, Weekend, Leave, ReturnConfirmed, Note, Attendance, Missing.
class AttendanceCalendarDay {
  final DateTime date;
  final bool isWeekend;
  final bool isHoliday;
  final String? holidayName;
  final int overtimeMinutes;
  final String morning;
  final String afternoon;
  final String morningSource;
  final String afternoonSource;
  final String? leaveTypeName;
  final String? morningNote;
  final String? afternoonNote;
  final DateTime? checkInTime;
  final DateTime? checkOutTime;

  AttendanceCalendarDay({
    required this.date,
    required this.isWeekend,
    this.isHoliday = false,
    this.holidayName,
    this.overtimeMinutes = 0,
    required this.morning,
    required this.afternoon,
    required this.morningSource,
    required this.afternoonSource,
    this.leaveTypeName,
    this.morningNote,
    this.afternoonNote,
    this.checkInTime,
    this.checkOutTime,
  });

  static DateTime? _dt(dynamic v) => v == null ? null : DateTime.parse(v as String);

  factory AttendanceCalendarDay.fromJson(Map<String, dynamic> json) {
    return AttendanceCalendarDay(
      date: DateTime.parse(json['date'] as String),
      isWeekend: json['isWeekend'] as bool? ?? false,
      isHoliday: json['isHoliday'] as bool? ?? false,
      holidayName: json['holidayName'] as String?,
      overtimeMinutes: (json['overtimeMinutes'] as num?)?.toInt() ?? 0,
      morning: json['morning'] as String? ?? 'None',
      afternoon: json['afternoon'] as String? ?? 'None',
      morningSource: json['morningSource'] as String? ?? 'None',
      afternoonSource: json['afternoonSource'] as String? ?? 'None',
      leaveTypeName: json['leaveTypeName'] as String?,
      morningNote: json['morningNote'] as String?,
      afternoonNote: json['afternoonNote'] as String?,
      checkInTime: _dt(json['checkInTime']),
      checkOutTime: _dt(json['checkOutTime']),
    );
  }
}

// Ghi chú ngoại lệ chấm công của một buổi (AttendanceNoteDto).
class AttendanceNote {
  final int id;
  final String employeeCode;
  final String employeeName;
  final DateTime date;
  final String session; // Morning | Afternoon
  final String status; // OnTime | Late | Absent
  final String note;
  final String createdByName;
  final DateTime createdAt;

  AttendanceNote({
    required this.id,
    required this.employeeCode,
    required this.employeeName,
    required this.date,
    required this.session,
    required this.status,
    required this.note,
    required this.createdByName,
    required this.createdAt,
  });

  factory AttendanceNote.fromJson(Map<String, dynamic> json) {
    return AttendanceNote(
      id: (json['id'] as num).toInt(),
      employeeCode: json['employeeCode'] as String,
      employeeName: json['employeeName'] as String,
      date: DateTime.parse(json['date'] as String),
      session: json['session'] as String,
      status: json['status'] as String,
      note: (json['note'] as String?) ?? '',
      createdByName: (json['createdByName'] as String?) ?? '',
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}

// Một buổi trong yêu cầu rút ngắn nghỉ phép. state: Pending | AwaitingHr | Active | Rejected.
class LeaveReturnSession {
  final DateTime date;
  final String session; // Morning | Afternoon
  final int leaveRequestId;
  final String leaveTypeName;
  final String state;
  final String? workedStatus; // OnTime | Late (do người xử lý xác nhận)

  LeaveReturnSession({
    required this.date,
    required this.session,
    required this.leaveRequestId,
    required this.leaveTypeName,
    required this.state,
    this.workedStatus,
  });

  factory LeaveReturnSession.fromJson(Map<String, dynamic> json) {
    return LeaveReturnSession(
      date: DateTime.parse(json['date'] as String),
      session: json['session'] as String,
      leaveRequestId: (json['leaveRequestId'] as num).toInt(),
      leaveTypeName: (json['leaveTypeName'] as String?) ?? '',
      state: json['state'] as String,
      workedStatus: json['workedStatus'] as String?,
    );
  }
}

// Bản xem trước các buổi sẽ được gỡ khỏi nghỉ phép nếu yêu cầu rút ngắn nghỉ phép được duyệt.
class LeaveReturnPreview {
  final List<LeaveReturnSession> sessions;
  final int sessionCount;
  final double refundDays;
  final List<int> leaveRequestIds;

  LeaveReturnPreview({
    required this.sessions,
    required this.sessionCount,
    required this.refundDays,
    required this.leaveRequestIds,
  });

  factory LeaveReturnPreview.fromJson(Map<String, dynamic> json) {
    return LeaveReturnPreview(
      sessions: (json['sessions'] as List)
          .map((e) => LeaveReturnSession.fromJson(e as Map<String, dynamic>))
          .toList(),
      sessionCount: (json['sessionCount'] as num).toInt(),
      refundDays: (json['refundDays'] as num).toDouble(),
      leaveRequestIds: (json['leaveRequestIds'] as List).map((e) => (e as num).toInt()).toList(),
    );
  }
}

// Yêu cầu rút ngắn nghỉ phép. status: PendingManager | PendingHr | Completed | Rejected.
class LeaveReturnRequest {
  final int id;
  final String employeeCode;
  final String employeeName;
  final DateTime fromDate;
  final String fromSession;
  final String reason;
  final String status;
  final List<LeaveReturnSession> sessions;
  final String? managerName;
  final DateTime? managerApprovedAt;
  final String? processedByName;
  final DateTime? processedAt;
  final String? rejectionReason;
  final DateTime createdAt;

  LeaveReturnRequest({
    required this.id,
    required this.employeeCode,
    required this.employeeName,
    required this.fromDate,
    required this.fromSession,
    required this.reason,
    required this.status,
    required this.sessions,
    this.managerName,
    this.managerApprovedAt,
    this.processedByName,
    this.processedAt,
    this.rejectionReason,
    required this.createdAt,
  });

  static DateTime? _dt(dynamic v) => v == null ? null : DateTime.parse(v as String);

  factory LeaveReturnRequest.fromJson(Map<String, dynamic> json) {
    return LeaveReturnRequest(
      id: (json['id'] as num).toInt(),
      employeeCode: json['employeeCode'] as String,
      employeeName: json['employeeName'] as String,
      fromDate: DateTime.parse(json['fromDate'] as String),
      fromSession: json['fromSession'] as String,
      reason: (json['reason'] as String?) ?? '',
      status: json['status'] as String,
      sessions: (json['sessions'] as List)
          .map((e) => LeaveReturnSession.fromJson(e as Map<String, dynamic>))
          .toList(),
      managerName: json['managerName'] as String?,
      managerApprovedAt: _dt(json['managerApprovedAt']),
      processedByName: json['processedByName'] as String?,
      processedAt: _dt(json['processedAt']),
      rejectionReason: json['rejectionReason'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}
