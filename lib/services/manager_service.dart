import 'package:dio/dio.dart';

import '../core/network/api_client.dart';
import '../models/manager_attendance.dart';
import '../models/manager_dashboard.dart';
import '../models/manager_employee.dart';
import '../models/manager_organization.dart';
import '../models/org_tree_node.dart';

// Gọi API cho nhóm màn hình Manager (dashboard, nhân viên, chấm công team, tổ chức, cây tổ chức).
class ManagerService {
  final ApiClient _apiClient;

  ManagerService(this._apiClient);

  Future<T> _run<T>(Future<T> Function() action, String fallback) async {
    try {
      return await action();
    } on DioException catch (e) {
      throw Exception(apiErrorMessage(e, fallback));
    }
  }

  List<Map<String, dynamic>> _list(dynamic data) => (data as List).cast<Map<String, dynamic>>();

  Future<ManagerDashboard> getDashboard(String managerCode) => _run(() async {
        final r = await _apiClient.dio.get('/dashboard/manager/$managerCode');
        return ManagerDashboard.fromJson(r.data as Map<String, dynamic>);
      }, 'Không thể tải dashboard.');

  // Toàn bộ cấp dưới (kể cả cấp dưới của cấp dưới).
  Future<List<ManagerEmployee>> getTeamRecursive(String managerCode) => _run(() async {
        final r = await _apiClient.dio.get('/employees/team/$managerCode/all');
        return _list(r.data).map(ManagerEmployee.fromJson).toList();
      }, 'Không thể tải danh sách nhân viên.');

  // Lấy mã phòng ban của chính quản lý để tải chấm công cả phòng.
  Future<String> getDepartmentCodeOf(String employeeCode) => _run(() async {
        final r = await _apiClient.dio.get('/employees/$employeeCode');
        return (r.data as Map<String, dynamic>)['departmentCode'] as String? ?? '';
      }, 'Không thể tải thông tin phòng ban.');

  Future<List<ManagerAttendanceRecord>> getDepartmentAttendance(
    String departmentCode,
    String startDate,
    String endDate,
  ) =>
      _run(() async {
        final r = await _apiClient.dio.get(
          '/attendance/department/$departmentCode',
          queryParameters: {'startDate': startDate, 'endDate': endDate},
        );
        return _list(r.data).map(ManagerAttendanceRecord.fromJson).toList();
      }, 'Không thể tải bảng chấm công.');

  Future<List<ManagerAttendanceAdjustment>> getPendingAdjustments() => _run(() async {
        final r = await _apiClient.dio.get('/attendance/adjustments/pending');
        return _list(r.data).map(ManagerAttendanceAdjustment.fromJson).toList();
      }, 'Không thể tải yêu cầu chỉnh sửa chấm công.');

  Future<void> approveAdjustment(int id) => _run(() async {
        await _apiClient.dio.put('/attendance/adjustments/$id/approve');
      }, 'Không thể duyệt yêu cầu.');

  Future<void> rejectAdjustment(int id) => _run(() async {
        await _apiClient.dio.put('/attendance/adjustments/$id/reject');
      }, 'Không thể từ chối yêu cầu.');

  Future<List<ManagerDepartment>> getDepartments() => _run(() async {
        final r = await _apiClient.dio.get('/departments');
        return _list(r.data).map(ManagerDepartment.fromJson).toList();
      }, 'Không thể tải danh sách phòng ban.');

  Future<List<ManagerPosition>> getPositions() => _run(() async {
        final r = await _apiClient.dio.get('/positions');
        return _list(r.data).map(ManagerPosition.fromJson).toList();
      }, 'Không thể tải danh sách chức vụ.');

  Future<List<OrgTreeNode>> getOrgTree() => _run(() async {
        final r = await _apiClient.dio.get('/employees/org-tree');
        return _list(r.data).map(OrgTreeNode.fromJson).toList();
      }, 'Không thể tải cây tổ chức.');
}
