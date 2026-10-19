import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../core/network/api_client.dart';
import '../../../services/hr_service.dart';
import '../../../services/leave_service.dart';
import '../../../services/live_updates.dart';
import '../../../services/manager_service.dart';
import '../../../services/overtime_service.dart';
import '../../dashboard/providers/menu_provider.dart';

// Số việc đang chờ xử lý của từng chức năng, hiện thành chấm đỏ trên ô ở màn Tiện ích.
// Khoá là route của chức năng (cùng route với menu backend), chỉ đếm chức năng mà tài khoản được cấp.
class PendingBadgeProvider extends ChangeNotifier {
  final MenuProvider _menu;
  final LiveUpdates _live;
  final LeaveService _leave;
  final HrService _hr;
  final ManagerService _manager;
  final OvertimeService _overtime;

  PendingBadgeProvider(ApiClient api, this._live, this._menu)
      : _leave = LeaveService(api),
        _hr = HrService(api),
        _manager = ManagerService(api),
        _overtime = OvertimeService(api) {
    // Có thông báo mới (đơn mới gửi, vừa được xử lý...) hoặc menu vừa tải xong thì đếm lại.
    _eventSub = _live.events.listen((_) => refresh());
    _menu.addListener(_onMenuChanged);
  }

  StreamSubscription<dynamic>? _eventSub;
  Map<String, int> _counts = {};
  bool _loading = false;
  bool _again = false;
  // Tăng khi đăng xuất để bỏ kết quả của request cũ trả về muộn (đổi tài khoản).
  int _epoch = 0;
  String _menuSignature = '';

  int countOf(String route) => _counts[route] ?? 0;

  void _onMenuChanged() {
    // Chỉ đếm lại khi tập chức năng của tài khoản đổi, không phải mỗi lần menu thông báo.
    final signature = _routes.join('|');
    if (signature == _menuSignature) return;
    _menuSignature = signature;
    refresh();
  }

  static const _leaveRoute = '/manager/leave';
  static const _attendanceRoute = '/manager/attendance';
  static const _adjustmentRoute = '/hr/adjustments';
  static const _returnRoute = '/hr/leave-returns';

  List<String> get _routes => [
        for (final r in [_leaveRoute, _attendanceRoute, _adjustmentRoute, _returnRoute])
          if (_menu.hasRoute(r)) r,
      ];

  Future<int> _count(Future<List<dynamic>> Function() fetch) async {
    try {
      return (await fetch()).length;
    } catch (_) {
      // Không có quyền hoặc lỗi mạng thoáng qua: coi như không có việc chờ.
      return 0;
    }
  }

  Future<void> refresh() async {
    if (_loading) {
      _again = true;
      return;
    }
    _loading = true;
    final epoch = _epoch;
    try {
      final routes = _routes;
      final next = <String, int>{};
      await Future.wait([
        if (routes.contains(_leaveRoute))
          // Duyệt đơn từ gồm: nghỉ phép, rút ngắn phép, hủy phép, làm thêm giờ.
          Future.wait([
            _count(_leave.getPending),
            _count(_hr.getPendingReturns),
            _count(_leave.getPendingCancels),
            _count(_overtime.getPending),
          ]).then((c) => next[_leaveRoute] = c.fold(0, (a, b) => a + b)),
        if (routes.contains(_attendanceRoute))
          _count(_manager.getPendingAdjustments).then((c) => next[_attendanceRoute] = c),
        if (routes.contains(_adjustmentRoute))
          _count(_hr.getAdjustmentsAwaitingProcessing).then((c) => next[_adjustmentRoute] = c),
        if (routes.contains(_returnRoute))
          _count(_hr.getReturnsAwaitingProcessing).then((c) => next[_returnRoute] = c),
      ]);
      if (epoch != _epoch) return;
      if (!mapEquals(_counts, next)) {
        _counts = next;
        notifyListeners();
      }
    } finally {
      if (epoch == _epoch) {
        _loading = false;
        if (_again) {
          _again = false;
          refresh();
        }
      }
    }
  }

  void clear() {
    _epoch++;
    _loading = false;
    _again = false;
    _menuSignature = '';
    if (_counts.isNotEmpty) {
      _counts = {};
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _eventSub?.cancel();
    _menu.removeListener(_onMenuChanged);
    super.dispose();
  }
}
