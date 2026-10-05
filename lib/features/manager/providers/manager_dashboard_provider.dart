import 'package:flutter/material.dart';

import '../../../models/manager_dashboard.dart';
import '../../../services/manager_service.dart';
import '../../auth/providers/auth_provider.dart';

class ManagerDashboardProvider extends ChangeNotifier {
  final ManagerService _service;
  final AuthProvider _auth;

  ManagerDashboardProvider(this._service, this._auth);

  ManagerDashboard? data;
  bool isLoading = false;
  String? errorMessage;

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
      data = await _service.getDashboard(code);
    } catch (e) {
      errorMessage = e.toString().replaceFirst('Exception: ', '');
    }
    isLoading = false;
    notifyListeners();
  }
}
