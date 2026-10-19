import 'package:enterprise_management/features/admin_system/widgets/permission_groups.dart';
import 'package:enterprise_management/models/system_permission.dart';
import 'package:flutter_test/flutter_test.dart';

SystemPermission _p(String code, {String? module}) => SystemPermission(
      permissionCode: code,
      permissionName: code,
      module: module ?? (code.startsWith('page.') ? 'page' : code.split('.').first),
      isActive: true,
    );

const _all = [
  'page.employee.dashboard', 'page.employee.attendance', 'page.employee.leave', 'attendance.punch', 'attendance.adjustment.self', 'leave.request.self',
  'page.manager.dashboard', 'page.manager.employees', 'page.manager.attendance', 'page.manager.leave', 'page.manager.organization', 'page.manager.orgtree',
  'dashboard.view.team', 'employee.view.team', 'attendance.view.team', 'attendance.adjustment.view', 'attendance.adjustment.approve', 'leave.request.view', 'leave.request.approve',
  'page.hr.attendance', 'page.hr.attendance-notes', 'page.hr.adjustments', 'page.hr.leave-returns',
  'attendance.view.all', 'attendance.note.manage', 'attendance.adjustment.apply', 'employee.view.all', 'leavebalance.manage',
  'page.admin.employees', 'page.admin.departments', 'page.admin.positions', 'page.admin.leavetypes', 'page.admin.audit', 'page.admin.system',
  'employee.manage', 'user.manage', 'department.manage', 'position.manage', 'leavetype.manage', 'role.manage', 'permission.manage', 'menu.manage', 'audit.view',
];

List<String> _codes(List<SystemPermission> items) => items.map((p) => p.permissionCode).toList();

void main() {
  final perms = _all.map(_p).toList();

  test('xếp đủ 43 quyền vào 4 nhóm, không còn nhóm Khác', () {
    final groups = buildPermissionGroups(perms);
    expect(groups.map((g) => g.key).toList(), ['employee', 'manager', 'hr', 'admin']);
    expect(groups.fold<int>(0, (n, g) => n + g.all.length), 43);
  });

  test('nhóm Nhân viên cơ bản gồm 3 menu và 3 quyền của chính mình', () {
    final g = buildPermissionGroups(perms).firstWhere((x) => x.key == 'employee');
    expect(_codes(g.menus), ['page.employee.dashboard', 'page.employee.attendance', 'page.employee.leave']);
    expect(_codes(g.actions), ['attendance.punch', 'attendance.adjustment.self', 'leave.request.self']);
  });

  test('employee.view.all thuộc nhóm HR, không thuộc Quản lý', () {
    final groups = buildPermissionGroups(perms);
    expect(_codes(groups.firstWhere((x) => x.key == 'hr').actions), contains('employee.view.all'));
    expect(_codes(groups.firstWhere((x) => x.key == 'manager').actions), isNot(contains('employee.view.all')));
  });

  test('menu mới chưa khai báo vào đúng nhóm theo tiền tố, quyền lạ vào nhóm Khác', () {
    final groups = buildPermissionGroups([_p('page.hr.payroll'), _p('page.manager.reports'), _p('bonus.approve')]);
    expect(_codes(groups.firstWhere((x) => x.key == 'hr').menus), ['page.hr.payroll']);
    expect(_codes(groups.firstWhere((x) => x.key == 'manager').menus), ['page.manager.reports']);
    expect(_codes(groups.firstWhere((x) => x.key == 'other').actions), ['bonus.approve']);
  });

  group('tick cả nhóm', () {
    final manager = buildPermissionGroups(perms).firstWhere((x) => x.key == 'manager');

    test('chưa chọn gì: tick nhóm chọn hết 13', () {
      expect(triState(manager.all, {}), false);
      final next = toggleMany(manager.all, {});
      expect(next.length, 13);
      expect(triState(manager.all, next), true);
    });

    test('đã chọn hết: tick lại thì bỏ chọn hết', () {
      final all = manager.all.map((p) => p.permissionCode).toSet();
      expect(toggleMany(manager.all, all), isEmpty);
    });

    test('chọn một phần (mixed): tick nhóm thì chọn nốt cho đủ, không đụng nhóm khác', () {
      final partial = {'page.manager.leave', 'attendance.punch'};
      expect(triState(manager.all, partial), null);
      final next = toggleMany(manager.all, partial);
      expect(triState(manager.all, next), true);
      expect(next, contains('attendance.punch'));
    });

    test('tick riêng phần menu chỉ chọn 6 menu, không chọn chức năng', () {
      final next = toggleMany(manager.menus, {});
      expect(next.length, 6);
      expect(next.every((c) => c.startsWith('page.manager.')), true);
    });
  });
}
