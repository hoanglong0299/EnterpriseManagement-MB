import 'package:flutter/material.dart';

import '../../../models/overtime.dart';
import '../../../services/overtime_service.dart';

// Làm thêm giờ của chính mình: hạn mức, danh sách đơn, gửi và hủy đơn.
class OvertimeProvider extends ChangeNotifier {
  final OvertimeService _service;

  OvertimeProvider(this._service);

  List<OvertimeRequest> items = [];
  OvertimeQuota? quota;
  bool isLoading = false;
  bool isSubmitting = false;
  int? busyId;
  String? error;

  // silent: tải ngầm (tự cập nhật), không bật cờ loading để giao diện không nhấp nháy.
  Future<void> load({bool silent = false}) async {
    if (!silent) {
      isLoading = true;
      error = null;
      notifyListeners();
    }
    try {
      final results = await Future.wait([_service.getMine(), _service.getQuota()]);
      items = (results[0] as List<OvertimeRequest>)..sort((a, b) => b.id.compareTo(a.id));
      quota = results[1] as OvertimeQuota;
    } catch (e) {
      if (!silent) error = e.toString().replaceFirst('Exception: ', '');
    }
    isLoading = false;
    notifyListeners();
  }

  // Trả về null nếu gửi được, ngược lại là thông báo lỗi nguyên văn của backend.
  Future<String?> submit({
    required DateTime date,
    required TimeOfDay start,
    required TimeOfDay end,
    required String reason,
  }) async {
    isSubmitting = true;
    notifyListeners();
    String? err;
    try {
      await _service.submit(
        date: date,
        startHour: start.hour,
        startMinute: start.minute,
        endHour: end.hour,
        endMinute: end.minute,
        reason: reason.trim(),
      );
    } catch (e) {
      err = e.toString().replaceFirst('Exception: ', '');
    }
    isSubmitting = false;
    notifyListeners();
    if (err == null) await load(silent: true);
    return err;
  }

  Future<String?> cancel(int id) async {
    busyId = id;
    notifyListeners();
    String? err;
    try {
      await _service.cancel(id);
    } catch (e) {
      err = e.toString().replaceFirst('Exception: ', '');
    }
    busyId = null;
    notifyListeners();
    await load(silent: true);
    return err;
  }
}

// Duyệt đơn làm thêm giờ của team (cùng cách làm với duyệt đơn nghỉ).
class OvertimeApprovalProvider extends ChangeNotifier {
  final OvertimeService _service;

  OvertimeApprovalProvider(this._service);

  List<OvertimeRequest> pending = [];
  List<OvertimeRequest> history = [];
  bool isLoading = false;
  int? busyId;
  String? error;

  Future<void> load({bool silent = false}) async {
    if (!silent) {
      isLoading = true;
      error = null;
      notifyListeners();
    }
    try {
      final results = await Future.wait([_service.getPending(), _service.getHistory()]);
      pending = results[0]..sort((a, b) => b.id.compareTo(a.id));
      history = results[1].where((r) => r.status != 'Pending').toList()..sort((a, b) => b.id.compareTo(a.id));
    } catch (e) {
      if (!silent) error = e.toString().replaceFirst('Exception: ', '');
    }
    isLoading = false;
    notifyListeners();
  }

  Future<String?> approve(int id) => _decide(id, () => _service.approve(id));

  Future<String?> reject(int id, String reason) {
    final trimmed = reason.trim();
    return _decide(id, () => _service.reject(id, trimmed.isEmpty ? null : trimmed));
  }

  // null = thành công. Thất bại cũng tải lại để bỏ đơn đã được người khác xử lý.
  Future<String?> _decide(int id, Future<void> Function() action) async {
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
    await load(silent: true);
    return err;
  }
}
