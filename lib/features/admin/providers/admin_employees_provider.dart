import 'package:flutter/material.dart';

import '../../../models/admin_employee.dart';
import '../../../models/admin_user.dart';
import '../../../models/department.dart';
import '../../../models/position.dart';
import '../../../services/admin_service.dart';
import '../widgets/admin_common.dart';

// Danh sách nhân viên + phòng ban + chức vụ + tài khoản theo nhân viên cho Admin > Quản lý nhân viên.
class AdminEmployeesProvider extends ChangeNotifier {
  final AdminService _service;
  final bool _canViewUsers;

  AdminEmployeesProvider(this._service, {required bool canViewUsers}) : _canViewUsers = canViewUsers;

  bool isLoading = false;
  String? errorMessage;
  List<AdminEmployee> employees = [];
  List<Department> departments = [];
  List<Position> positions = [];

  // Tài khoản đăng nhập gắn theo mã nhân viên: để biết hồ sơ nào đã có tài khoản.
  Map<String, List<AdminUser>> usersByEmployee = {};

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
                (e.email ?? '').toLowerCase().contains(query))) {
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
      ]);
      employees = results[0] as List<AdminEmployee>;
      departments = results[1] as List<Department>;
      positions = results[2] as List<Position>;
      await _loadUsers();
    } catch (e) {
      errorMessage = errText(e);
    }
    isLoading = false;
    notifyListeners();
  }

  Future<void> _loadUsers() async {
    if (!_canViewUsers) {
      usersByEmployee = {};
      return;
    }
    try {
      final list = await _service.getUsers();
      final map = <String, List<AdminUser>>{};
      for (final u in list) {
        if (u.employeeCode == null) continue;
        map.putIfAbsent(u.employeeCode!, () => []).add(u);
      }
      usersByEmployee = map;
    } catch (_) {
      usersByEmployee = {};
    }
  }

  Future<void> _reloadEmployees() async {
    employees = await _service.getEmployees();
    notifyListeners();
  }

  Future<void> _reloadUsers() async {
    await _loadUsers();
    notifyListeners();
  }

  // Các hàm ghi ném Exception khi lỗi để màn hình hiện thông báo.
  Future<void> create({
    required String firstName,
    required String lastName,
    String? email,
    String? phone,
    String? address,
    String? dateOfBirth,
    required String gender,
    required String departmentCode,
    required String positionCode,
    String? managerCode,
    required String hireDate,
  }) async {
    await _service.createEmployee(
      firstName: firstName,
      lastName: lastName,
      email: email,
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
  }

  Future<void> update(
    AdminEmployee e, {
    required String firstName,
    required String lastName,
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
      phone: phone,
      address: address,
      departmentCode: departmentCode,
      positionCode: positionCode,
      managerCode: managerCode,
    );
    await _reloadEmployees();
  }

  Future<void> setActive(AdminEmployee e, bool active) async {
    await _service.setEmployeeActive(e.employeeCode, active);
    await _reloadEmployees();
  }

  Future<AdminCredential> createAccount(AdminEmployee e, String username, String email) async {
    // Vai trò do backend tự lấy theo chức vụ khi không truyền roleCode (giống web).
    final result = await _service.createUser(username: username, email: email, employeeCode: e.employeeCode);
    await _reloadUsers();
    return result;
  }

  Future<void> setAccountActive(AdminUser u, bool active) async {
    await _service.setUserActive(u.username, active);
    await _reloadUsers();
  }

  Future<AdminCredential> resetPassword(AdminUser u) => _service.resetPassword(u.username);
}
