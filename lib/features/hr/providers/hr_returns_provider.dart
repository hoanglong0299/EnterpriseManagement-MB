import 'package:flutter/material.dart';

import '../../../core/utils/helpers.dart';
import '../../../models/attendance_hr.dart';
import '../../../services/hr_service.dart';

// Xử lý yêu cầu đi làm lại (quyền attendance.note.manage).
class HrReturnsProvider extends ChangeNotifier {
  final HrService _service;

  HrReturnsProvider(this._service);

  List<LeaveReturnRequest> items = [];
  bool isLoading = false;
  String? error;
  int? busyId;

  Future<void> load() async {
    isLoading = true;
    error = null;
    notifyListeners();
    try {
      items = await _service.getReturnsAwaitingProcessing();
    } catch (e) {
      error = e.toString().replaceFirst('Exception: ', '');
    }
    isLoading = false;
    notifyListeners();
  }

  // statuses: key "yyyy-MM-dd|Session" -> OnTime | Late cho từng buổi AwaitingHr.
  Future<String?> confirm(LeaveReturnRequest r, Map<String, String> statuses) {
    final awaiting = r.sessions.where((s) => s.state == 'AwaitingHr');
    final list = awaiting
        .map((s) => {
              'date': isoDate(s.date),
              'session': s.session,
              'status': statuses['${isoDate(s.date)}|${s.session}'] ?? 'OnTime',
            })
        .toList();
    return _run(r.id, () => _service.processReturn(r.id, list));
  }

  Future<String?> reject(int id, String reason) =>
      _run(id, () => _service.rejectReturnProcessing(id, reason: reason.isEmpty ? null : reason));

  // Trả về null nếu thành công, ngược lại là message lỗi nguyên văn.
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
