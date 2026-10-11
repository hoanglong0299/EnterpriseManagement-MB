// Số liệu tổng quan của quản lý (GET /dashboard/manager/{code}).
class ManagerDashboard {
  final int teamSize;
  final int pendingLeaveRequestsCount;
  final int pendingAttendanceAdjustmentsCount;
  final int teamPresentTodayCount;
  final int teamAbsentTodayCount;
  // Số người trong team đang nghỉ phép hôm nay; null nếu backend chưa trả.
  final int? teamOnLeaveTodayCount;

  ManagerDashboard({
    required this.teamSize,
    required this.pendingLeaveRequestsCount,
    required this.pendingAttendanceAdjustmentsCount,
    required this.teamPresentTodayCount,
    required this.teamAbsentTodayCount,
    this.teamOnLeaveTodayCount,
  });

  factory ManagerDashboard.fromJson(Map<String, dynamic> json) {
    int n(String key) => (json[key] as num?)?.toInt() ?? 0;
    return ManagerDashboard(
      teamSize: n('teamSize'),
      pendingLeaveRequestsCount: n('pendingLeaveRequestsCount'),
      pendingAttendanceAdjustmentsCount: n('pendingAttendanceAdjustmentsCount'),
      teamPresentTodayCount: n('teamPresentTodayCount'),
      teamAbsentTodayCount: n('teamAbsentTodayCount'),
      teamOnLeaveTodayCount: (json['teamOnLeaveTodayCount'] as num?)?.toInt(),
    );
  }
}
