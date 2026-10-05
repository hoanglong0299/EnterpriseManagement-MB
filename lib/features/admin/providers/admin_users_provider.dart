import 'package:flutter/material.dart';

import '../../../models/admin_employee.dart';
import '../../../models/admin_user.dart';
import '../../../services/admin_service.dart';
import '../widgets/admin_common.dart';

// Danh sách tài khoản + vai trò + nhân viên (để gắn tài khoản) cho Admin > Tài khoản.
class AdminUsersProvider extends ChangeNotifier {
  final AdminService _service;

  AdminUsersProvider(this._service);

  bool isLoading = false;
  String? errorMessage;
  List<AdminUser> users = [];
  List<AdminRole> roles = [];
  List<AdminEmployee> employees = [];

  String employeeCodeFilter = '';
  String employeeNameFilter = '';

  bool get hasFilters => employeeCodeFilter.isNotEmpty || employeeNameFilter.isNotEmpty;

  // Lọc theo mã / tên nhân viên như web.
  List<AdminUser> get filtered => users.where((u) {
        if (employeeCodeFilter.isNotEmpty &&
            !(u.employeeCode ?? '').toLowerCase().contains(employeeCodeFilter.toLowerCase())) {
          return false;
        }
        if (employeeNameFilter.isNotEmpty &&
            !(u.employeeName ?? '').toLowerCase().contains(employeeNameFilter.toLowerCase())) {
          return false;
        }
        return true;
      }).toList();

  void setFilters({String? code, String? name}) {
    if (code != null) employeeCodeFilter = code.trim();
    if (name != null) employeeNameFilter = name.trim();
    notifyListeners();
  }

  void clearFilters() {
    employeeCodeFilter = '';
    employeeNameFilter = '';
    notifyListeners();
  }

  Future<void> load() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();
    try {
      users = await _service.getUsers();
      roles = await _service.getRoles();
      // Danh sách nhân viên chỉ để chọn khi tạo tài khoản; thiếu quyền xem thì bỏ qua.
      try {
        employees = await _service.getEmployees();
      } catch (_) {
        employees = [];
      }
    } catch (e) {
      errorMessage = errText(e);
    }
    isLoading = false;
    notifyListeners();
  }

  Future<void> _reloadUsers() async {
    users = await _service.getUsers();
    notifyListeners();
  }

  Future<AdminCredential> create({
    required String username,
    required String email,
    required String roleCode,
    String? employeeCode,
  }) async {
    final result = await _service.createUser(
      username: username,
      email: email,
      roleCode: roleCode,
      employeeCode: employeeCode,
    );
    await _reloadUsers();
    return result;
  }

  Future<void> update(AdminUser u, {required String email, String? employeeCode, required List<String> roleCodes}) async {
    await _service.updateUser(u.username, email: email, employeeCode: employeeCode, roleCodes: roleCodes);
    await _reloadUsers();
  }

  Future<void> setActive(AdminUser u, bool active) async {
    await _service.setUserActive(u.username, active);
    await _reloadUsers();
  }

  Future<AdminCredential> resetPassword(AdminUser u) => _service.resetPassword(u.username);
}
