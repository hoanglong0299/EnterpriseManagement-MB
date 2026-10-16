import 'package:dio/dio.dart';

import '../core/network/api_client.dart';
import '../models/admin_employee.dart';
import '../models/department.dart';
import '../models/position.dart';

// Gọi API quản trị: nhân viên (kèm tài khoản), phòng ban, chức vụ (tương ứng userApi/employeeApi/departmentApi/positionApi bên web).
class AdminService {
  final ApiClient _apiClient;

  AdminService(this._apiClient);

  Future<T> _run<T>(Future<T> Function() action, String fallback) async {
    try {
      return await action();
    } on DioException catch (e) {
      throw Exception(apiErrorMessage(e, fallback));
    }
  }

  List<Map<String, dynamic>> _list(Response response) =>
      (response.data as List).map((e) => e as Map<String, dynamic>).toList();

  // Cần quyền role.manage; không có quyền thì trả danh sách rỗng (khi đó dùng vai trò mặc định theo chức vụ).
  Future<List<AdminRole>> getRoles() async {
    try {
      final r = await _apiClient.dio.get('/roles');
      return _list(r).map(AdminRole.fromJson).where((e) => e.isActive).toList();
    } on DioException {
      return [];
    }
  }

  // ---- Tài khoản gắn với nhân viên (user.manage) ----
  Future<void> setAccountActive(String username, bool isActive) => _run(() async {
        await _apiClient.dio.put('/users/$username/active', data: {'isActive': isActive});
      }, 'Không thể cập nhật trạng thái tài khoản.');

  Future<AdminCredential> resetPassword(String username) => _run(() async {
        final r = await _apiClient.dio.post('/users/$username/reset-password');
        final data = r.data as Map<String, dynamic>;
        return AdminCredential(
          username: (data['username'] as String?) ?? username,
          password: data['generatedPassword'] as String,
          isReset: true,
        );
      }, 'Không thể đặt lại mật khẩu.');

  // ---- Nhân viên (employee.view.all / employee.manage) ----
  Future<List<AdminEmployee>> getEmployees() => _run(() async {
        final r = await _apiClient.dio.get('/employees');
        return _list(r).map(AdminEmployee.fromJson).toList();
      }, 'Không thể tải danh sách nhân viên.');

  Future<CreateEmployeeResult> createEmployee({
    required String firstName,
    required String lastName,
    required String username,
    required String email,
    String? roleCode,
    String? phone,
    String? address,
    String? dateOfBirth,
    required String gender,
    required String departmentCode,
    required String positionCode,
    String? managerCode,
    required String hireDate,
  }) =>
      _run(() async {
        final r = await _apiClient.dio.post('/employees', data: {
          'firstName': firstName,
          'lastName': lastName,
          'username': username,
          'email': email,
          'roleCode': roleCode,
          'phone': phone,
          'address': address,
          'dateOfBirth': dateOfBirth,
          'gender': gender,
          'departmentCode': departmentCode,
          'positionCode': positionCode,
          'managerCode': managerCode,
          'hireDate': hireDate,
        });
        return CreateEmployeeResult.fromJson(r.data as Map<String, dynamic>);
      }, 'Không thể thêm nhân viên.');

  Future<void> updateEmployee(
    String employeeCode, {
    required String firstName,
    required String lastName,
    required String email,
    required List<String> roleCodes,
    String? phone,
    String? address,
    required String departmentCode,
    required String positionCode,
    String? managerCode,
  }) =>
      _run(() async {
        await _apiClient.dio.put('/employees/$employeeCode', data: {
          'firstName': firstName,
          'lastName': lastName,
          'email': email,
          'roleCodes': roleCodes,
          'phone': phone,
          'address': address,
          'departmentCode': departmentCode,
          'positionCode': positionCode,
          'managerCode': managerCode,
        });
      }, 'Không thể cập nhật hồ sơ nhân viên.');

  Future<void> setEmployeeActive(String employeeCode, bool isActive) => _run(() async {
        await _apiClient.dio.put('/employees/$employeeCode/active', data: {'isActive': isActive});
      }, 'Không thể cập nhật trạng thái nhân viên.');

  // ---- Phòng ban (department.manage) ----
  Future<List<Department>> getDepartments() => _run(() async {
        final r = await _apiClient.dio.get('/departments');
        return _list(r).map(Department.fromJson).toList();
      }, 'Không thể tải danh sách phòng ban.');

  Future<void> createDepartment({required String code, required String name, String? description}) =>
      _run(() async {
        await _apiClient.dio.post('/departments', data: {
          'departmentCode': code,
          'departmentName': name,
          'description': description,
        });
      }, 'Không thể thêm phòng ban.');

  Future<void> setDepartmentActive(String code, bool isActive) => _run(() async {
        await _apiClient.dio.put('/departments/$code/active', data: {'isActive': isActive});
      }, 'Không thể cập nhật trạng thái phòng ban.');

  // ---- Chức vụ (position.manage) ----
  Future<List<Position>> getPositions() => _run(() async {
        final r = await _apiClient.dio.get('/positions');
        return _list(r).map(Position.fromJson).toList();
      }, 'Không thể tải danh sách chức vụ.');

  Future<void> createPosition({required String code, required String name, String? description}) =>
      _run(() async {
        await _apiClient.dio.post('/positions', data: {
          'positionCode': code,
          'positionName': name,
          'description': description,
        });
      }, 'Không thể thêm chức vụ.');

  Future<void> updatePosition(String code, {required String name, String? description}) => _run(() async {
        await _apiClient.dio.put('/positions/$code', data: {
          'positionName': name,
          'description': description,
        });
      }, 'Không thể cập nhật chức vụ.');

  Future<void> setPositionActive(String code, bool isActive) => _run(() async {
        await _apiClient.dio.put('/positions/$code/active', data: {'isActive': isActive});
      }, 'Không thể cập nhật trạng thái chức vụ.');

  Future<void> setStandardSalary(String code, double salary) => _run(() async {
        await _apiClient.dio.put('/positions/$code/salary', data: {'standardSalary': salary});
      }, 'Không thể cập nhật lương chuẩn.');
}
