import 'package:flutter/material.dart';

import '../../../models/employee.dart';
import '../../../services/employee_service.dart';
import '../../auth/providers/auth_provider.dart';

class ProfileProvider extends ChangeNotifier {
  final EmployeeService _employeeService;
  final AuthProvider _authProvider;

  ProfileProvider(this._employeeService, this._authProvider);

  Employee? employee;
  String? errorMessage;

  // Chua tai duoc ho so thi tam dung ten dang nhap de man hinh khong bi trong.
  String get displayName => employee?.fullName ?? _authProvider.session?.username ?? '';

  Future<void> load() async {
    final employeeCode = _authProvider.session?.employeeCode;
    if (employeeCode == null) return;

    errorMessage = null;
    try {
      employee = await _employeeService.getByCode(employeeCode);
    } catch (e) {
      errorMessage = e.toString().replaceFirst('Exception: ', '');
    }
    notifyListeners();
  }

  // Cap nhat SDT/dia chi (backend chi cho tai khoan co quyen employee.manage). Tra ve true neu thanh cong.
  Future<bool> updateContact({required String phone, required String address}) async {
    final current = employee;
    if (current == null) return false;
    errorMessage = null;
    try {
      employee = await _employeeService.updateContact(current, phone: phone, address: address);
      notifyListeners();
      return true;
    } catch (e) {
      errorMessage = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  // Dung khi dang xuat de nguoi dang nhap ke tiep khong thay ho so cua nguoi truoc.
  void clear() {
    employee = null;
    errorMessage = null;
    notifyListeners();
  }
}
