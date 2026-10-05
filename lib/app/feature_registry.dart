import 'package:flutter/material.dart';

import '../features/admin/screens/admin_departments_screen.dart';
import '../features/admin/screens/admin_employees_screen.dart';
import '../features/admin/screens/admin_positions_screen.dart';
import '../features/admin/screens/admin_users_screen.dart';
import '../features/admin_system/screens/admin_audit_screen.dart';
import '../features/admin_system/screens/admin_system_screen.dart';
import '../features/attendance/screens/employee_attendance_screen.dart';
import '../features/employee_dashboard/screens/employee_dashboard_screen.dart';
import '../features/leave/screens/leave_approval_screen.dart';
import '../features/leave/screens/leave_record_screen.dart';
import '../features/manager/screens/manager_attendance_screen.dart';
import '../features/manager/screens/manager_dashboard_screen.dart';
import '../features/manager/screens/manager_employees_screen.dart';
import '../features/manager/screens/manager_org_tree_screen.dart';
import '../features/manager/screens/manager_organization_screen.dart';

// Một chức năng của app = 1 route menu của backend (cùng route với bản web) + màn hình + icon trên Home.
// Home chỉ hiện icon của chức năng mà /menus/mine trả về cho tài khoản, nên Admin bật/tắt menu trên web là app đổi theo.
// Tên hiển thị lấy từ menu backend (menuName); [fallbackTitle] chỉ dùng khi không có.
class AppFeature {
  final String route;
  final String fallbackTitle;
  final IconData icon;
  final Color color;
  final WidgetBuilder builder;

  const AppFeature({
    required this.route,
    required this.fallbackTitle,
    required this.icon,
    required this.color,
    required this.builder,
  });
}

// Muốn thêm chức năng mới cho app: thêm 1 dòng ở đây (route trùng với route menu trên web).
final List<AppFeature> appFeatures = [
  // Employee
  AppFeature(route: '/employee/dashboard', fallbackTitle: 'Dashboard', icon: Icons.dashboard_outlined, color: const Color(0xFF5C6BC0), builder: (_) => const EmployeeDashboardScreen()),
  AppFeature(route: '/employee/attendance', fallbackTitle: 'Chấm công', icon: Icons.location_on, color: const Color(0xFFE69D35), builder: (_) => const EmployeeAttendanceScreen()),
  AppFeature(route: '/employee/leave', fallbackTitle: 'Xin nghỉ phép', icon: Icons.flight_takeoff, color: const Color(0xFF2FA2B1), builder: (_) => const LeaveRecordScreen()),
  // Manager
  AppFeature(route: '/manager/dashboard', fallbackTitle: 'Dashboard tổng quan', icon: Icons.insights, color: const Color(0xFF5C6BC0), builder: (_) => const ManagerDashboardScreen()),
  AppFeature(route: '/manager/employees', fallbackTitle: 'Quản lý nhân viên', icon: Icons.groups, color: const Color(0xFF26A69A), builder: (_) => const ManagerEmployeesScreen()),
  AppFeature(route: '/manager/attendance', fallbackTitle: 'Quản lý chấm công', icon: Icons.access_time_filled, color: const Color(0xFFE69D35), builder: (_) => const ManagerAttendanceScreen()),
  AppFeature(route: '/manager/leave', fallbackTitle: 'Duyệt đơn xin nghỉ', icon: Icons.fact_check, color: const Color(0xFF3F51B5), builder: (_) => const LeaveApprovalScreen()),
  AppFeature(route: '/manager/organization', fallbackTitle: 'Phòng ban & chức vụ', icon: Icons.apartment, color: const Color(0xFF8D6E63), builder: (_) => const ManagerOrganizationScreen()),
  AppFeature(route: '/manager/org-tree', fallbackTitle: 'Cây tổ chức', icon: Icons.account_tree, color: const Color(0xFF7E57C2), builder: (_) => const ManagerOrgTreeScreen()),
  // Admin
  AppFeature(route: '/admin/users', fallbackTitle: 'Tài khoản', icon: Icons.admin_panel_settings, color: const Color(0xFFD84315), builder: (_) => const AdminUsersScreen()),
  AppFeature(route: '/admin/employees', fallbackTitle: 'Quản lý nhân viên', icon: Icons.badge, color: const Color(0xFF26A69A), builder: (_) => const AdminEmployeesScreen()),
  AppFeature(route: '/admin/departments', fallbackTitle: 'Phòng ban', icon: Icons.business, color: const Color(0xFF8D6E63), builder: (_) => const AdminDepartmentsScreen()),
  AppFeature(route: '/admin/positions', fallbackTitle: 'Chức vụ', icon: Icons.work_outline, color: const Color(0xFF6D4C41), builder: (_) => const AdminPositionsScreen()),
  AppFeature(route: '/admin/audit', fallbackTitle: 'Audit Log', icon: Icons.history, color: const Color(0xFF546E7A), builder: (_) => const AdminAuditScreen()),
  AppFeature(route: '/admin/system', fallbackTitle: 'System Administration', icon: Icons.settings, color: const Color(0xFF455A64), builder: (_) => const AdminSystemScreen()),
];
