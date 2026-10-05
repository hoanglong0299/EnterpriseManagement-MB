import 'package:flutter/material.dart';

import '../../../models/employee_dashboard_data.dart';
import '../../../services/dashboard_service.dart';
import '../../auth/providers/auth_provider.dart';

class EmployeeDashboardProvider extends ChangeNotifier {
  final DashboardService _service;
  final AuthProvider _auth;

  EmployeeDashboardProvider(this._service, this._auth);

  bool isLoading = false;
  String? errorMessage;
  EmployeeDashboardData? data;

  Future<void> load() async {
    final code = _auth.session?.employeeCode;
    if (code == null) {
      errorMessage = 'Tài khoản chưa gắn hồ sơ nhân viên. Liên hệ Admin để được liên kết.';
      notifyListeners();
      return;
    }
    // Chỉ hiện vòng quay toàn màn hình ở lần tải đầu; các lần làm mới sau giữ nguyên nội dung cũ.
    isLoading = data == null;
    errorMessage = null;
    notifyListeners();
    try {
      data = await _service.getEmployeeDashboard(code);
    } catch (e) {
      errorMessage = e.toString().replaceFirst('Exception: ', '');
    }
    isLoading = false;
    notifyListeners();
  }
}
