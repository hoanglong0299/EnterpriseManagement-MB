import 'package:dio/dio.dart';

import '../core/network/api_client.dart';
import '../models/audit_log.dart';
import '../models/system_leave_type.dart';
import '../models/system_menu.dart';
import '../models/system_permission.dart';
import '../models/system_role.dart';

// Gọi API quản trị hệ thống: audit log, role, permission, menu, loại nghỉ phép.
class SystemAdminService {
  final ApiClient _apiClient;

  SystemAdminService(this._apiClient);

  Dio get _dio => _apiClient.dio;

  Future<T> _run<T>(Future<T> Function() call, String fallback) async {
    try {
      return await call();
    } on DioException catch (e) {
      throw Exception(apiErrorMessage(e, fallback));
    }
  }

  List<T> _list<T>(Response<dynamic> r, T Function(Map<String, dynamic>) parse) =>
      (r.data as List).map((e) => parse(e as Map<String, dynamic>)).toList();

  // date dạng yyyy-MM-dd; backend trả toàn bộ log khớp bộ lọc (không phân trang phía server).
  Future<List<AuditLog>> getAuditLogs({String? username, String? module, String? action, String? date}) {
    final query = <String, String>{
      if (username != null && username.isNotEmpty) 'username': username,
      if (module != null && module.isNotEmpty) 'module': module,
      if (action != null && action.isNotEmpty) 'action': action,
      if (date != null && date.isNotEmpty) 'date': date,
    };
    return _run(() async => _list(await _dio.get('/audit-logs', queryParameters: query), AuditLog.fromJson),
        'Không tải được audit log.');
  }

  // ---- Role ----
  Future<List<SystemRole>> getRoles() =>
      _run(() async => _list(await _dio.get('/roles'), SystemRole.fromJson), 'Không tải được danh sách vai trò.');

  Future<void> createRole({required String code, required String name, String? description, required List<String> permissions}) =>
      _run(() => _dio.post('/roles', data: {
            'roleCode': code,
            'roleName': name,
            'description': description,
            'permissions': permissions,
          }), 'Không tạo được vai trò.');

  Future<void> updateRole(String code, {required String name, String? description, required List<String> permissions}) =>
      _run(() => _dio.put('/roles/$code', data: {
            'roleName': name,
            'description': description,
            'permissions': permissions,
          }), 'Không cập nhật được vai trò.');

  Future<void> setRoleActive(String code, bool isActive) =>
      _run(() => _dio.put('/roles/$code/active', data: {'isActive': isActive}), 'Không đổi được trạng thái vai trò.');

  // ---- Permission ----
  Future<List<SystemPermission>> getPermissions() => _run(
      () async => _list(await _dio.get('/permissions'), SystemPermission.fromJson), 'Không tải được danh sách permission.');

  Future<void> createPermission({required String code, required String name, required String module, String? description}) =>
      _run(() => _dio.post('/permissions', data: {
            'permissionCode': code,
            'permissionName': name,
            'module': module,
            'description': description,
          }), 'Không tạo được permission.');

  Future<void> updatePermission(String code, {required String name, required String module, String? description}) =>
      _run(() => _dio.put('/permissions/$code', data: {
            'permissionName': name,
            'module': module,
            'description': description,
          }), 'Không cập nhật được permission.');

  Future<void> setPermissionActive(String code, bool isActive) => _run(
      () => _dio.put('/permissions/$code/active', data: {'isActive': isActive}), 'Không đổi được trạng thái permission.');

  // ---- Menu ----
  Future<List<SystemMenu>> getMenus() =>
      _run(() async => _list(await _dio.get('/menus'), SystemMenu.fromJson), 'Không tải được danh sách menu.');

  Future<void> createMenu({
    required String code,
    required String name,
    String? icon,
    required String route,
    required int displayOrder,
    required List<String> permissions,
  }) =>
      _run(() => _dio.post('/menus', data: {
            'menuCode': code,
            'menuName': name,
            'icon': icon,
            'route': route,
            'displayOrder': displayOrder,
            'permissions': permissions,
          }), 'Không tạo được menu.');

  Future<void> updateMenu(
    String code, {
    required String name,
    String? icon,
    required String route,
    required int displayOrder,
    required List<String> permissions,
  }) =>
      _run(() => _dio.put('/menus/$code', data: {
            'menuName': name,
            'icon': icon,
            'route': route,
            'displayOrder': displayOrder,
            'permissions': permissions,
          }), 'Không cập nhật được menu.');

  Future<void> setMenuVisible(String code, bool isVisible) =>
      _run(() => _dio.put('/menus/$code/visible', data: {'isVisible': isVisible}), 'Không đổi được ẩn/hiện menu.');

  Future<void> setMenuActive(String code, bool isActive) =>
      _run(() => _dio.put('/menus/$code/active', data: {'isActive': isActive}), 'Không đổi được trạng thái menu.');

  // ---- Loại nghỉ phép (backend chỉ có GET danh sách + POST tạo) ----
  Future<List<SystemLeaveType>> getLeaveTypes() => _run(
      () async => _list(await _dio.get('/leave-types'), SystemLeaveType.fromJson), 'Không tải được loại nghỉ phép.');

  Future<void> createLeaveType({
    required String code,
    required String name,
    required double accrualAmount,
    required String accrualUnit,
    required String accrualPeriod,
    required bool isPaid,
    String? description,
  }) =>
      _run(() => _dio.post('/leave-types', data: {
            'leaveTypeCode': code,
            'leaveTypeName': name,
            'accrualAmount': accrualAmount,
            'accrualUnit': accrualUnit,
            'accrualPeriod': accrualPeriod,
            'isPaid': isPaid,
            'description': description,
          }), 'Không tạo được loại nghỉ phép.');
}
