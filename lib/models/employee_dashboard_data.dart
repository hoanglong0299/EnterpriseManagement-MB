import 'attendance_record.dart';

// Số liệu dashboard nhân viên (EmployeeDashboardDto ở backend).
class EmployeeDashboardData {
  final String employeeCode;
  final String employeeName;
  final AttendanceRecord? todayAttendance;
  final double totalRemainingLeaveDays;
  final int pendingLeaveRequestsCount;
  final int pendingAttendanceAdjustmentsCount;

  EmployeeDashboardData({
    required this.employeeCode,
    required this.employeeName,
    this.todayAttendance,
    required this.totalRemainingLeaveDays,
    required this.pendingLeaveRequestsCount,
    required this.pendingAttendanceAdjustmentsCount,
  });

  factory EmployeeDashboardData.fromJson(Map<String, dynamic> json) {
    final today = json['todayAttendance'];
    return EmployeeDashboardData(
      employeeCode: json['employeeCode'] as String,
      employeeName: json['employeeName'] as String,
      todayAttendance: today == null ? null : AttendanceRecord.fromJson(today as Map<String, dynamic>),
      totalRemainingLeaveDays: (json['totalRemainingLeaveDays'] as num?)?.toDouble() ?? 0,
      pendingLeaveRequestsCount: (json['pendingLeaveRequestsCount'] as num?)?.toInt() ?? 0,
      pendingAttendanceAdjustmentsCount: (json['pendingAttendanceAdjustmentsCount'] as num?)?.toInt() ?? 0,
    );
  }
}
