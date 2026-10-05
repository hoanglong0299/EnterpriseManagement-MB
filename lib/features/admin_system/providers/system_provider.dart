import 'package:flutter/material.dart';

import '../../../models/system_leave_type.dart';
import '../../../models/system_menu.dart';
import '../../../models/system_permission.dart';
import '../../../models/system_role.dart';
import '../../../services/system_admin_service.dart';
import 'audit_provider.dart' show cleanError;

// Trạng thái tải của 1 phần (vai trò, permission, menu, loại nghỉ).
class SectionState<T> {
  bool loading = false;
  bool loaded = false;
  String? error;
  List<T> items = [];
}

// Dữ liệu 4 phần của trang System Administration. Các hàm ghi trả về null nếu thành công, hoặc thông báo lỗi.
class SystemProvider extends ChangeNotifier {
  final SystemAdminService _service;

  SystemProvider(this._service);

  final roles = SectionState<SystemRole>();
  final permissions = SectionState<SystemPermission>();
  final menus = SectionState<SystemMenu>();
  final leaveTypes = SectionState<SystemLeaveType>();

  // Web ẩn menu đăng nhập admin nội bộ khỏi danh sách cấu hình.
  static const String hiddenMenuRoute = '/internal/admin-login';

  Future<void> _load<T>(SectionState<T> s, Future<List<T>> Function() fetch) async {
    s.loading = true;
    s.error = null;
    notifyListeners();
    try {
      s.items = await fetch();
      s.loaded = true;
    } catch (e) {
      s.error = cleanError(e);
    }
    s.loading = false;
    notifyListeners();
  }

  Future<void> loadRoles() => _load(roles, _service.getRoles);
  Future<void> loadPermissions() => _load(permissions, _service.getPermissions);
  Future<void> loadMenus() => _load(menus, () async => (await _service.getMenus()).where((m) => m.route != hiddenMenuRoute).toList());
  Future<void> loadLeaveTypes() => _load(leaveTypes, _service.getLeaveTypes);

  // Tải lần đầu cho phần chưa có dữ liệu.
  Future<void> ensurePermissions() async {
    if (!permissions.loaded && !permissions.loading) await loadPermissions();
  }

  Future<String?> _write(Future<void> Function() call, Future<void> Function() reload) async {
    try {
      await call();
    } catch (e) {
      return cleanError(e);
    }
    await reload();
    return null;
  }

  // ---- Role ----
  Future<String?> saveRole({
    SystemRole? editing,
    required String code,
    required String name,
    String? description,
    required List<String> permissionCodes,
  }) =>
      _write(
        () => editing == null
            ? _service.createRole(code: code, name: name, description: description, permissions: permissionCodes)
            : _service.updateRole(editing.roleCode, name: name, description: description, permissions: permissionCodes),
        loadRoles,
      );

  Future<String?> setRoleActive(SystemRole r, bool v) => _write(() => _service.setRoleActive(r.roleCode, v), loadRoles);

  // ---- Permission ----
  Future<String?> savePermission({
    SystemPermission? editing,
    required String code,
    required String name,
    required String module,
    String? description,
  }) =>
      _write(
        () => editing == null
            ? _service.createPermission(code: code, name: name, module: module, description: description)
            : _service.updatePermission(editing.permissionCode, name: name, module: module, description: description),
        loadPermissions,
      );

  Future<String?> setPermissionActive(SystemPermission p, bool v) =>
      _write(() => _service.setPermissionActive(p.permissionCode, v), loadPermissions);

  // ---- Menu ----
  Future<String?> saveMenu({
    SystemMenu? editing,
    required String code,
    required String name,
    String? icon,
    required String route,
    required int displayOrder,
    required List<String> permissionCodes,
  }) =>
      _write(
        () => editing == null
            ? _service.createMenu(code: code, name: name, icon: icon, route: route, displayOrder: displayOrder, permissions: permissionCodes)
            : _service.updateMenu(editing.menuCode, name: name, icon: icon, route: route, displayOrder: displayOrder, permissions: permissionCodes),
        loadMenus,
      );

  Future<String?> setMenuVisible(SystemMenu m, bool v) => _write(() => _service.setMenuVisible(m.menuCode, v), loadMenus);
  Future<String?> setMenuActive(SystemMenu m, bool v) => _write(() => _service.setMenuActive(m.menuCode, v), loadMenus);

  // ---- Loại nghỉ phép ----
  Future<String?> createLeaveType({
    required String code,
    required String name,
    required double amount,
    required String unit,
    required String period,
    required bool isPaid,
    String? description,
  }) =>
      _write(
        () => _service.createLeaveType(
            code: code, name: name, accrualAmount: amount, accrualUnit: unit, accrualPeriod: period, isPaid: isPaid, description: description),
        loadLeaveTypes,
      );
}
