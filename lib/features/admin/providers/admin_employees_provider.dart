import 'package:flutter/material.dart';

import '../../../models/admin_employee.dart';
import '../../../models/department.dart';
import '../../../models/position.dart';
import '../../../services/admin_service.dart';
import '../widgets/admin_common.dart';

// Danh sách nhân viên (kèm tài khoản) + phòng ban + chức vụ + vai trò cho Admin > Quản lý nhân viên.
class AdminEmployeesProvider extends ChangeNotifier {
  final AdminService _service;

  AdminEmployeesProvider(this._service);

  bool isLoading = false;
  String? errorMessage;
  List<AdminEmployee> employees = [];
  List<Department> departments = [];
  List<Position> positions = [];

  // Vai trò đang hoạt động (rỗng nếu không có quyền role.manage).
  List<AdminRole> roles = [];

  String query = '';
  String? departmentFilter;
  String? statusFilter; // Active / Probation / Terminated...

  void setQuery(String v) {
    query = v.trim().toLowerCase();
    notifyListeners();
  }

  void setDepartmentFilter(String? v) {
    departmentFilter = v;
    notifyListeners();
  }

  void setStatusFilter(String? v) {
    statusFilter = v;
    notifyListeners();
  }

  List<String> get statuses => (employees.map((e) => e.employmentStatus).toSet().toList())..sort();

  List<AdminEmployee> get filtered => employees.where((e) {
        if (departmentFilter != null && e.departmentCode != departmentFilter) return false;
        if (statusFilter != null && e.employmentStatus != statusFilter) return false;
        if (query.isNotEmpty &&
            !(e.fullName.toLowerCase().contains(query) ||
                e.employeeCode.toLowerCase().contains(query) ||
                e.email.toLowerCase().contains(query) ||
                e.username.toLowerCase().contains(query))) {
          return false;
        }
        return true;
      }).toList();

  String managerName(AdminEmployee e) {
    if (e.managerCode == null) return '';
    for (final m in employees) {
      if (m.employeeCode == e.managerCode) return m.fullName;
    }
    return e.managerName ?? e.managerCode!;
  }

  Future<void> load() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();
    try {
      final results = await Future.wait([
        _service.getEmployees(),
        _service.getDepartments(),
        _service.getPositions(),
        _service.getRoles(),
      ]);
      employees = results[0] as List<AdminEmployee>;
      departments = results[1] as List<Department>;
      positions = results[2] as List<Position>;
      roles = results[3] as List<AdminRole>;
    } catch (e) {
      errorMessage = errText(e);
    }
    isLoading = false;
    notifyListeners();
  }

  Future<void> _reloadEmployees() async {
    employees = await _service.getEmployees();
    notifyListeners();
  }

  // Các hàm ghi ném Exception khi lỗi để màn hình hiện thông báo.
  Future<AdminCredential> create({
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
  }) async {
    final result = await _service.createEmployee(
      firstName: firstName,
      lastName: lastName,
      username: username,
      email: email,
      roleCode: roleCode,
      phone: phone,
      address: address,
      dateOfBirth: dateOfBirth,
      gender: gender,
      departmentCode: departmentCode,
      positionCode: positionCode,
      managerCode: managerCode,
      hireDate: hireDate,
    );
    await _reloadEmployees();
    return AdminCredential(username: result.employee.username, password: result.generatedPassword, isReset: false);
  }

  Future<void> update(
    AdminEmployee e, {
    required String firstName,
    required String lastName,
    required String email,
    required List<String> roleCodes,
    String? phone,
    String? address,
    required String departmentCode,
    required String positionCode,
    String? managerCode,
  }) async {
    await _service.updateEmployee(
      e.employeeCode,
      firstName: firstName,
      lastName: lastName,
      email: email,
      roleCodes: roleCodes,
      phone: phone,
      address: address,
      departmentCode: departmentCode,
      positionCode: positionCode,
      managerCode: managerCode,
    );
    await _reloadEmployees();
  }

  // Cho nghỉ việc/phục hồi: backend khoá/mở tài khoản theo.
  Future<void> setActive(AdminEmployee e, bool active) async {
    await _service.setEmployeeActive(e.employeeCode, active);
    await _reloadEmployees();
  }

  Future<void> setAccountActive(AdminEmployee e, bool active) async {
    await _service.setAccountActive(e.username, active);
    await _reloadEmployees();
  }

  Future<AdminCredential> resetPassword(AdminEmployee e) => _service.resetPassword(e.username);
}
