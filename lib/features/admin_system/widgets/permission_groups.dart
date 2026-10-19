import '../../../models/system_permission.dart';

// Gom menu (permission "page.*") và quyền hành động theo NHÓM CHỨC NĂNG, giống bản web, để Admin gán cho một vai trò
// theo cụm: tick ô đầu nhóm là chọn cả nhóm. Chỉ là cách sắp xếp hiển thị, giá trị chọn vẫn là danh sách mã quyền.
class PermissionGroupDef {
  final String key;
  final String label;
  final String hint;
  final List<String> menus;
  final List<String> actions;

  const PermissionGroupDef({
    required this.key,
    required this.label,
    required this.hint,
    this.menus = const [],
    this.actions = const [],
  });
}

const List<PermissionGroupDef> functionalGroups = [
  PermissionGroupDef(
    key: 'employee',
    label: 'Nhân viên cơ bản (ai cũng có)',
    hint: 'Chấm công, xem lịch sử chấm công của mình, xin điều chỉnh công, xin nghỉ phép.',
    menus: ['page.employee.dashboard', 'page.employee.attendance', 'page.employee.leave', 'page.employee.overtime'],
    actions: ['attendance.punch', 'attendance.adjustment.self', 'leave.request.self', 'overtime.request.self'],
  ),
  PermissionGroupDef(
    key: 'manager',
    label: 'Quản lý (trưởng nhóm, trưởng phòng)',
    hint: 'Xem nhân viên và chấm công của team, duyệt đơn nghỉ phép, xác nhận điều chỉnh công, cây tổ chức.',
    menus: [
      'page.manager.dashboard',
      'page.manager.employees',
      'page.manager.attendance',
      'page.manager.timesheet',
      'page.manager.leave',
      'page.manager.organization',
      'page.manager.orgtree',
    ],
    actions: [
      'dashboard.view.team',
      'employee.view.team',
      'attendance.view.team',
      'attendance.adjustment.view',
      'attendance.adjustment.approve',
      'leave.request.view',
      'leave.request.approve',
      'overtime.request.view',
      'overtime.request.approve',
    ],
  ),
  PermissionGroupDef(
    key: 'hr',
    label: 'Nhân sự (HR)',
    hint: 'Chấm công toàn công ty, ghi nhận ngoại lệ, xử lý điều chỉnh công và đi làm lại, bảng công tháng, ngày nghỉ lễ, cấp lại số ngày nghỉ.',
    menus: ['page.hr.attendance', 'page.hr.adjustments', 'page.hr.leave-returns', 'page.hr.attendance-notes', 'page.hr.timesheet', 'page.hr.holidays'],
    actions: [
      'attendance.view.all',
      'attendance.note.manage',
      'attendance.adjustment.apply',
      'employee.view.all',
      'leavebalance.manage',
      'timesheet.manage',
      'holiday.manage',
    ],
  ),
  PermissionGroupDef(
    key: 'admin',
    label: 'Quản trị hệ thống (Admin)',
    hint: 'Quản lý nhân viên và tài khoản, phòng ban, chức vụ, loại nghỉ, vai trò, quyền, menu và nhật ký hệ thống.',
    menus: [
      'page.admin.employees',
      'page.admin.departments',
      'page.admin.positions',
      'page.admin.leavetypes',
      'page.admin.audit',
      'page.admin.system',
    ],
    actions: [
      'employee.manage',
      'user.manage',
      'department.manage',
      'position.manage',
      'leavetype.manage',
      'role.manage',
      'permission.manage',
      'menu.manage',
      'audit.view',
    ],
  ),
];

const PermissionGroupDef otherGroupDef = PermissionGroupDef(
  key: 'other',
  label: 'Khác',
  hint: 'Các quyền chưa thuộc nhóm nào ở trên (ví dụ quyền mới được thêm sau).',
);

// Menu mới chưa khai báo vẫn vào đúng nhóm theo tiền tố của mã trang.
const Map<String, String> _pagePrefixGroup = {
  'page.employee.': 'employee',
  'page.manager.': 'manager',
  'page.hr.': 'hr',
  'page.admin.': 'admin',
};

class PermissionGroup {
  final PermissionGroupDef def;
  final List<SystemPermission> menus = [];
  final List<SystemPermission> actions = [];

  PermissionGroup(this.def);

  String get key => def.key;
  String get label => def.label;
  String get hint => def.hint;
  List<SystemPermission> get all => [...menus, ...actions];
}

List<PermissionGroup> buildPermissionGroups(List<SystemPermission> permissions) {
  final groups = <String, PermissionGroup>{
    for (final def in functionalGroups) def.key: PermissionGroup(def),
    otherGroupDef.key: PermissionGroup(otherGroupDef),
  };
  final explicit = <String, String>{
    for (final def in functionalGroups)
      for (final code in [...def.menus, ...def.actions]) code: def.key,
  };
  final order = <String, int>{
    for (final def in functionalGroups) ...{
      for (final entry in [...def.menus, ...def.actions].asMap().entries) entry.value: entry.key,
    },
  };

  for (final p in permissions) {
    final isMenu = p.module == 'page' || p.permissionCode.startsWith('page.');
    var key = explicit[p.permissionCode];
    if (key == null && isMenu) {
      for (final entry in _pagePrefixGroup.entries) {
        if (p.permissionCode.startsWith(entry.key)) {
          key = entry.value;
          break;
        }
      }
    }
    final group = groups[key ?? otherGroupDef.key]!;
    (isMenu ? group.menus : group.actions).add(p);
  }

  int byOrder(SystemPermission a, SystemPermission b) {
    final c = (order[a.permissionCode] ?? 999).compareTo(order[b.permissionCode] ?? 999);
    return c != 0 ? c : a.permissionName.compareTo(b.permissionName);
  }

  for (final g in groups.values) {
    g.menus.sort(byOrder);
    g.actions.sort(byOrder);
  }
  return groups.values.where((g) => g.menus.isNotEmpty || g.actions.isNotEmpty).toList();
}

// Trạng thái ô tick của một tập quyền: false = không chọn, null = chọn một phần, true = chọn hết.
bool? triState(List<SystemPermission> items, Set<String> selected) {
  final count = items.where((p) => selected.contains(p.permissionCode)).length;
  if (count == 0) return false;
  return count == items.length ? true : null;
}

// Tick cả nhóm/phần: đã chọn hết thì bỏ chọn hết, ngược lại chọn hết.
Set<String> toggleMany(List<SystemPermission> items, Set<String> selected) {
  final next = {...selected};
  final allChecked = triState(items, selected) == true;
  for (final p in items) {
    allChecked ? next.remove(p.permissionCode) : next.add(p.permissionCode);
  }
  return next;
}
