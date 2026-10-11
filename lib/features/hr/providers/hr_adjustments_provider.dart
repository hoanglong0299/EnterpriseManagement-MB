import 'package:flutter/material.dart';

import '../../../models/attendance_adjustment.dart';
import '../../../services/hr_service.dart';

// Xử lý điều chỉnh công sau khi Manager duyệt (quyền attendance.adjustment.apply).
class HrAdjustmentsProvider extends ChangeNotifier {
  final HrService _service;

  HrAdjustmentsProvider(this._service);

  List<AttendanceAdjustment> items = [];
  bool isLoading = false;
  String? error;
  int? busyId;

  Future<void> load() async {
    isLoading = true;
    error = null;
    notifyListeners();
    try {
      items = await _service.getAdjustmentsAwaitingProcessing();
    } catch (e) {
      error = e.toString().replaceFirst('Exception: ', '');
    }
    isLoading = false;
    notifyListeners();
  }

  // Trả về null nếu thành công, ngược lại là message lỗi nguyên văn.
  Future<String?> apply(int id) => _run(id, () => _service.applyAdjustment(id));

  Future<String?> reject(int id, String reason) =>
      _run(id, () => _service.rejectAdjustmentProcessing(id, reason: reason.isEmpty ? null : reason));

  Future<String?> _run(int id, Future<void> Function() action) async {
    busyId = id;
    notifyListeners();
    String? err;
    try {
      await action();
    } catch (e) {
      err = e.toString().replaceFirst('Exception: ', '');
    }
    busyId = null;
    notifyListeners();
    if (err == null) await load();
    return err;
  }
}
