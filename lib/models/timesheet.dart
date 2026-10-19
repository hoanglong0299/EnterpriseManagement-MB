// Bảng công tháng của HR (TimesheetDto) và ngày nghỉ lễ (HolidayDto).

class Holiday {
  final int id;
  final DateTime date;
  final String name;

  const Holiday({required this.id, required this.date, required this.name});

  factory Holiday.fromJson(Map<String, dynamic> json) => Holiday(
        id: (json['id'] as num).toInt(),
        date: DateTime.parse(json['date'] as String),
        name: json['name'] as String? ?? '',
      );
}

class TimesheetRow {
  final String employeeCode;
  final String employeeName;
  final String departmentName;
  final double workedDays;
  final double leaveDays;
  final double absentDays;
  final int lateSessions;
  final double overtimeHours;

  const TimesheetRow({
    required this.employeeCode,
    required this.employeeName,
    required this.departmentName,
    required this.workedDays,
    required this.leaveDays,
    required this.absentDays,
    required this.lateSessions,
    required this.overtimeHours,
  });

  factory TimesheetRow.fromJson(Map<String, dynamic> json) => TimesheetRow(
        employeeCode: json['employeeCode'] as String? ?? '',
        employeeName: json['employeeName'] as String? ?? '',
        departmentName: json['departmentName'] as String? ?? '',
        workedDays: (json['workedDays'] as num?)?.toDouble() ?? 0,
        leaveDays: (json['leaveDays'] as num?)?.toDouble() ?? 0,
        absentDays: (json['absentDays'] as num?)?.toDouble() ?? 0,
        lateSessions: (json['lateSessions'] as num?)?.toInt() ?? 0,
        overtimeHours: (json['overtimeHours'] as num?)?.toDouble() ?? 0,
      );
}

class Timesheet {
  final int year;
  final int month;
  final int standardDays;
  final bool isClosed;
  final DateTime? closedAt;
  final String? closedByName;
  final List<TimesheetRow> rows;

  const Timesheet({
    required this.year,
    required this.month,
    required this.standardDays,
    required this.isClosed,
    this.closedAt,
    this.closedByName,
    required this.rows,
  });

  factory Timesheet.fromJson(Map<String, dynamic> json) => Timesheet(
        year: (json['year'] as num).toInt(),
        month: (json['month'] as num).toInt(),
        standardDays: (json['standardDays'] as num?)?.toInt() ?? 0,
        isClosed: json['isClosed'] as bool? ?? false,
        closedAt: json['closedAt'] == null ? null : DateTime.parse(json['closedAt'] as String),
        closedByName: json['closedByName'] as String?,
        rows: ((json['rows'] as List?) ?? const [])
            .map((e) => TimesheetRow.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

// 18.5 -> "18,5"; 20.0 -> "20" (số ngày công hiển thị theo kiểu Việt Nam).
String dayCountLabel(double value) {
  final text = value == value.roundToDouble() ? value.toInt().toString() : value.toString();
  return text.replaceAll('.', ',');
}
