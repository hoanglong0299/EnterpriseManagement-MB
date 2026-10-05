import 'package:flutter/material.dart';

import '../../../models/audit_log.dart';
import '../../../services/system_admin_service.dart';

String cleanError(Object e) => e.toString().replaceFirst('Exception: ', '');

// Danh sách audit log: backend trả toàn bộ log khớp bộ lọc, app cuộn dần từng trang [pageSize] dòng.
class AuditProvider extends ChangeNotifier {
  static const int pageSize = 20;

  final SystemAdminService _service;

  AuditProvider(this._service);

  bool isLoading = false;
  String? error;
  List<AuditLog> _all = [];
  int _visible = pageSize;

  // Bộ lọc đang áp dụng (date dạng yyyy-MM-dd).
  String username = '';
  String module = '';
  String action = '';
  String date = '';

  List<AuditLog> get logs => _all.take(_visible).toList();
  int get total => _all.length;
  bool get hasMore => _visible < _all.length;
  bool get hasFilter => username.isNotEmpty || module.isNotEmpty || action.isNotEmpty || date.isNotEmpty;

  Future<void> load() async {
    isLoading = true;
    error = null;
    notifyListeners();
    try {
      _all = await _service.getAuditLogs(username: username, module: module, action: action, date: date);
      _visible = pageSize;
    } catch (e) {
      error = cleanError(e);
      _all = [];
    }
    isLoading = false;
    notifyListeners();
  }

  void applyFilter({required String username, required String module, required String action, required String date}) {
    this.username = username.trim();
    this.module = module.trim();
    this.action = action.trim();
    this.date = date;
    load();
  }

  void clearFilter() => applyFilter(username: '', module: '', action: '', date: '');

  void loadMore() {
    if (!hasMore) return;
    _visible += pageSize;
    notifyListeners();
  }
}
