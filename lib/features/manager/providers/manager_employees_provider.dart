import 'package:flutter/material.dart';

import '../../../models/manager_employee.dart';
import '../../../services/manager_service.dart';
import '../../auth/providers/auth_provider.dart';

class ManagerEmployeesProvider extends ChangeNotifier {
  final ManagerService _service;
  final AuthProvider _auth;

  ManagerEmployeesProvider(this._service, this._auth);

  List<ManagerEmployee> employees = [];
  bool isLoading = false;
  String? errorMessage;

  // Bộ lọc phía app (web chỉ hiện bảng, mobile thêm tìm kiếm/lọc cho dễ dùng).
  String keyword = '';
  String? departmentFilter; // departmentName
  String? statusFilter; // Active / Inactive...

  List<String> get departments => (employees.map((e) => e.departmentName).toSet().toList()..sort());
  List<String> get statuses => (employees.map((e) => e.employmentStatus).toSet().toList()..sort());

  List<ManagerEmployee> get filtered {
    final k = keyword.trim().toLowerCase();
    return employees.where((e) {
      if (departmentFilter != null && e.departmentName != departmentFilter) return false;
      if (statusFilter != null && e.employmentStatus != statusFilter) return false;
      if (k.isEmpty) return true;
      return e.fullName.toLowerCase().contains(k) ||
          e.employeeCode.toLowerCase().contains(k) ||
          (e.email ?? '').toLowerCase().contains(k) ||
          e.positionName.toLowerCase().contains(k);
    }).toList();
  }

  void setKeyword(String v) {
    keyword = v;
    notifyListeners();
  }

  void setDepartment(String? v) {
    departmentFilter = v;
    notifyListeners();
  }

  void setStatus(String? v) {
    statusFilter = v;
    notifyListeners();
  }

  Future<void> load() async {
    final code = _auth.session?.employeeCode;
    if (code == null) {
      errorMessage = 'Tài khoản chưa gắn với nhân viên nào.';
      notifyListeners();
      return;
    }
    isLoading = true;
    errorMessage = null;
    notifyListeners();
    try {
      employees = await _service.getTeamRecursive(code);
    } catch (e) {
      errorMessage = e.toString().replaceFirst('Exception: ', '');
    }
    isLoading = false;
    notifyListeners();
  }
}
