// Số liệu tổng quan của quản lý (GET /dashboard/manager/{code}).
class ManagerDashboard {
  final int teamSize;
  final int pendingLeaveRequestsCount;
  final int pendingAttendanceAdjustmentsCount;
  final int teamPresentTodayCount;
  final int teamAbsentTodayCount;

  ManagerDashboard({
    required this.teamSize,
    required this.pendingLeaveRequestsCount,
    required this.pendingAttendanceAdjustmentsCount,
    required this.teamPresentTodayCount,
    required this.teamAbsentTodayCount,
  });

  factory ManagerDashboard.fromJson(Map<String, dynamic> json) {
    int n(String key) => (json[key] as num?)?.toInt() ?? 0;
    return ManagerDashboard(
      teamSize: n('teamSize'),
      pendingLeaveRequestsCount: n('pendingLeaveRequestsCount'),
      pendingAttendanceAdjustmentsCount: n('pendingAttendanceAdjustmentsCount'),
      teamPresentTodayCount: n('teamPresentTodayCount'),
      teamAbsentTodayCount: n('teamAbsentTodayCount'),
    );
  }
}
