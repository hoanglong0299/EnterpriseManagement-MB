import 'package:flutter/material.dart';

import '../../../models/leave_balance.dart';
import '../../../models/leave_cancel.dart';
import '../../../models/leave_request.dart';
import '../../../models/leave_type.dart';
import '../../../services/leave_service.dart';
import '../../auth/providers/auth_provider.dart';

class LeaveProvider extends ChangeNotifier {
  final LeaveService _leaveService;
  final AuthProvider _authProvider;

  LeaveProvider(this._leaveService, this._authProvider);

  // Form tren man hinh chi co 2 nhom ("Nghi phep", "Nghi che do"), moi nhom ung voi 1 ma loai nghi cua backend.
  static const String annualCode = 'ANNUAL';
  static const String regimeCode = 'REGIME';

  bool _isLoading = false;
  String? errorMessage;
  List<LeaveType> _types = [];
  List<LeaveBalance> _balances = [];
  List<LeaveRequest> _requests = [];
  List<LeaveCancelRequest> _cancels = [];

  bool get isLoading => _isLoading;
  List<LeaveType> get types => _types;
  List<LeaveBalance> get balances => _balances;
  List<LeaveRequest> get requests => _requests;
  List<LeaveCancelRequest> get cancels => _cancels;

  // Yêu cầu hủy đang chờ duyệt của một đơn nghỉ (nếu có).
  LeaveCancelRequest? pendingCancelFor(int leaveRequestId) {
    for (final c in _cancels) {
      if (c.leaveRequestId == leaveRequestId && c.isPending) return c;
    }
    return null;
  }

  // Đơn đã duyệt và chưa có buổi nào bắt đầu thì mới xin hủy được (backend kiểm tra lại).
  bool canRequestCancel(LeaveRequest r) =>
      r.status == 'Approved' && r.startDate.isAfter(DateTime.now()) && pendingCancelFor(r.id) == null;

  // Đơn nhiều ngày đã duyệt, đã bắt đầu nghỉ và còn ít nhất 1 ngày làm việc (từ ngày mai tới hết đơn): cho xin rút ngắn.
  bool canShorten(LeaveRequest r) {
    if (r.status != 'Approved') return false;
    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);
    final start = DateTime(r.startDate.year, r.startDate.month, r.startDate.day);
    final end = DateTime(r.endDate.year, r.endDate.month, r.endDate.day);
    if (!end.isAfter(start) || start.isAfter(todayDate)) return false;
    for (var d = todayDate.add(const Duration(days: 1)); !d.isAfter(end); d = d.add(const Duration(days: 1))) {
      if (d.weekday != DateTime.saturday && d.weekday != DateTime.sunday) return true;
    }
    return false;
  }

  // Dinh dang Map {title, value, category} la dinh dang Dashboard va LeaveStatusScreen dang doc.
  List<Map<String, dynamic>> get leaveStatusList {
    final paidByCode = {for (final t in _types) t.leaveTypeCode: t.isPaid};
    return _balances.map((b) {
      final unit = b.unit == 'Hours' ? 'giờ' : 'ngày';
      final isPaid = paidByCode[b.leaveTypeCode] ?? true;
      return {
        'title': b.leaveTypeName,
        'value': '${_trimNumber(b.remainingTime)} $unit',
        'category': isPaid ? 'Nghỉ có lương' : 'Nghỉ không lương',
      };
    }).toList();
  }

  // Dinh dang Map {type, appliedAt, date, time, reason} la dinh dang the lich su trong LeaveRecordScreen dang doc.
  // Backend khong tra ngay tao don, nen o cho "appliedAt" hien trang thai don.
  // 'id' va 'status' la 2 khoa them de man hinh biet don nao dang cho duyet va huy dung don do.
  List<Map<String, String>> get historyForDisplay {
    return _requests.map((r) {
      var reason = r.reason ?? '';
      if (r.status == 'Rejected' && (r.rejectionReason ?? '').isNotEmpty) {
        reason = '$reason (Từ chối: ${r.rejectionReason})';
      }

      return {
        'id': r.id.toString(),
        'status': r.status,
        'type': r.leaveTypeName,
        'appliedAt': r.statusLabel,
        'date': r.dateLabel,
        'time': r.timeLabel,
        'reason': reason,
      };
    }).toList();
  }

  // silent: tải ngầm (tự cập nhật), không bật cờ loading để giao diện không nhấp nháy.
  Future<void> load({bool silent = false}) async {
    final employeeCode = _authProvider.session?.employeeCode;
    if (employeeCode == null) return;

    if (!silent) {
      _isLoading = true;
      errorMessage = null;
      notifyListeners();
    }

    try {
      final results = await Future.wait([
        _leaveService.getTypes(),
        _leaveService.getBalances(employeeCode, DateTime.now().year),
        _leaveService.getMyRequests(),
        _leaveService.getMyCancels(),
      ]);
      _types = results[0] as List<LeaveType>;
      _balances = results[1] as List<LeaveBalance>;
      // Id lon hon = don tao sau, xep don moi nhat len dau nhu giao dien cu.
      _requests = (results[2] as List<LeaveRequest>)..sort((a, b) => b.id.compareTo(a.id));
      _cancels = results[3] as List<LeaveCancelRequest>;
    } catch (e) {
      if (!silent) errorMessage = e.toString().replaceFirst('Exception: ', '');
    } finally {
      if (!silent) _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> submitAnnual({
    required DateTime date,
    TimeOfDay? startTime,
    TimeOfDay? endTime,
    required String reason,
  }) {
    return _submit(
      leaveTypeCode: annualCode,
      startDate: date,
      endDate: date,
      session: _sessionFor(startTime, endTime),
      reason: reason,
    );
  }

  Future<bool> submitRegime({
    required DateTimeRange range,
    required String reason,
  }) {
    return _submit(
      leaveTypeCode: regimeCode,
      startDate: range.start,
      endDate: range.end,
      session: 'FullDay',
      reason: reason,
    );
  }

  // Gui don theo loai nghi bat ky (giong form web): nghi ngay/nhieu ngay co buoi nghi.
  Future<bool> submitLeave({
    required String leaveTypeCode,
    required DateTime startDate,
    required DateTime endDate,
    required String session,
    required String reason,
  }) {
    return _submit(
      leaveTypeCode: leaveTypeCode,
      startDate: startDate,
      endDate: endDate,
      session: session,
      reason: reason,
    );
  }

  // Nghi ngan: 1 khung 30 phut trong hom nay.
  Future<bool> submitShortLeave({
    required String leaveTypeCode,
    required DateTime start,
    required DateTime end,
    required String reason,
  }) async {
    errorMessage = null;
    try {
      await _leaveService.submitShort(leaveTypeCode: leaveTypeCode, start: start, end: end, reason: reason);
    } catch (e) {
      errorMessage = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return false;
    }
    await load();
    return true;
  }

  // Tra ve true neu gui thanh cong; neu that bai, errorMessage chua noi dung loi tu backend.
  Future<bool> _submit({
    required String leaveTypeCode,
    required DateTime startDate,
    required DateTime endDate,
    required String session,
    required String reason,
  }) async {
    errorMessage = null;
    try {
      await _leaveService.submit(
        leaveTypeCode: leaveTypeCode,
        startDate: startDate,
        endDate: endDate,
        session: session,
        reason: reason,
      );
    } catch (e) {
      errorMessage = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return false;
    }
    await load();
    return true;
  }

  // Chi huy duoc don cua chinh minh khi con "Cho duyet" (backend kiem tra, sai thi tra loi kem message).
  Future<bool> cancel(int id) async {
    errorMessage = null;
    try {
      await _leaveService.cancel(id);
    } catch (e) {
      errorMessage = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return false;
    }
    await load();
    return true;
  }

  // Xin hủy đơn nghỉ đã duyệt (chưa bắt đầu). Trả về true nếu gửi được, ngược lại errorMessage chứa lý do.
  Future<bool> requestCancel(int leaveRequestId, String reason) async {
    errorMessage = null;
    try {
      await _leaveService.submitCancel(leaveRequestId, reason);
    } catch (e) {
      errorMessage = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return false;
    }
    await load(silent: true);
    return true;
  }

  Future<bool> withdrawCancel(int cancelId) async {
    errorMessage = null;
    try {
      await _leaveService.withdrawCancel(cancelId);
    } catch (e) {
      errorMessage = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return false;
    }
    await load(silent: true);
    return true;
  }

  // Dung khi dang xuat de nguoi dang nhap ke tiep khong thay du lieu cua nguoi truoc.
  void clear() {
    _cancels = [];
    _types = [];
    _balances = [];
    _requests = [];
    errorMessage = null;
    _isLoading = false;
    notifyListeners();
  }

  // Backend chi nhan buoi nghi (Morning/Afternoon/FullDay), khong nhan khung gio tu do:
  // khung gio nam tron buoi sang -> Morning, tron buoi chieu -> Afternoon, con lai -> FullDay.
  String _sessionFor(TimeOfDay? start, TimeOfDay? end) {
    if (start == null || end == null) return 'FullDay';
    final startMinutes = start.hour * 60 + start.minute;
    final endMinutes = end.hour * 60 + end.minute;
    if (endMinutes <= 12 * 60) return 'Morning';
    if (startMinutes >= 13 * 60) return 'Afternoon';
    return 'FullDay';
  }

  String _trimNumber(double value) {
    return value == value.roundToDouble() ? value.toInt().toString() : value.toString();
  }
}
