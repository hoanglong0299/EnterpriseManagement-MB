import 'package:flutter/material.dart';

import '../../../models/leave_type_admin.dart';
import '../../../services/leave_type_admin_service.dart';

String _clean(Object e) => e.toString().replaceFirst('Exception: ', '');

// Danh sách loại nghỉ phép cho Admin. Các hàm ghi trả về null nếu thành công, hoặc thông báo lỗi của backend.
class AdminLeaveTypesProvider extends ChangeNotifier {
  final LeaveTypeAdminService _service;

  AdminLeaveTypesProvider(this._service);

  bool isLoading = false;
  bool loaded = false;
  String? error;
  List<LeaveTypeAdmin> items = [];

  Future<void> load() async {
    isLoading = true;
    error = null;
    notifyListeners();
    try {
      items = await _service.getAll();
      loaded = true;
    } catch (e) {
      error = _clean(e);
    }
    isLoading = false;
    notifyListeners();
  }

  Future<String?> _write(Future<void> Function() call) async {
    try {
      await call();
    } catch (e) {
      return _clean(e);
    }
    await load();
    return null;
  }

  Future<String?> save({
    LeaveTypeAdmin? editing,
    required String code,
    required String name,
    required double amount,
    required String unit,
    required String period,
    required bool isPaid,
    String? description,
  }) =>
      _write(() => editing == null
          ? _service.create(code: code, name: name, amount: amount, unit: unit, period: period, isPaid: isPaid, description: description)
          : _service.update(editing.leaveTypeCode,
              name: name, amount: amount, unit: unit, period: period, isPaid: isPaid, description: description));

  Future<String?> setActive(LeaveTypeAdmin t, bool value) => _write(() => _service.setActive(t.leaveTypeCode, value));

  Future<String?> delete(LeaveTypeAdmin t) => _write(() => _service.delete(t.leaveTypeCode));
}
