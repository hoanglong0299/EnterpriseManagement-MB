import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../models/leave_balance.dart';
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

  bool get isLoading => _isLoading;

  // Dinh dang Map {title, value, category} la dinh dang Dashboard va LeaveStatusScreen dang doc.
  List<Map<String, dynamic>> get leaveStatusList {
    final paidByCode = {for (final t in _types) t.leaveTypeCode: t.isPaid};
    return _balances.map((b) {
      final unit = b.unit == 'Hours' ? 'Hours' : 'Days';
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
  List<Map<String, String>> get historyForDisplay {
    final dateFormat = DateFormat('dd/MM/yyyy');
    return _requests.map((r) {
      final sameDay = dateFormat.format(r.startDate) == dateFormat.format(r.endDate);
      final dateStr = sameDay
          ? dateFormat.format(r.startDate)
          : '${dateFormat.format(r.startDate)} - ${dateFormat.format(r.endDate)}';

      var reason = r.reason ?? '';
      if (r.status == 'Rejected' && (r.rejectionReason ?? '').isNotEmpty) {
        reason = '$reason (Từ chối: ${r.rejectionReason})';
      }

      return {
        'type': r.leaveTypeName,
        'appliedAt': _statusLabel(r.status),
        'date': dateStr,
        'time': _timeLabel(r),
        'reason': reason,
      };
    }).toList();
  }

  Future<void> load() async {
    final employeeCode = _authProvider.session?.employeeCode;
    if (employeeCode == null) return;

    _isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      final results = await Future.wait([
        _leaveService.getTypes(),
        _leaveService.getBalances(employeeCode, DateTime.now().year),
        _leaveService.getMyRequests(),
      ]);
      _types = results[0] as List<LeaveType>;
      _balances = results[1] as List<LeaveBalance>;
      // Id lon hon = don tao sau, xep don moi nhat len dau nhu giao dien cu.
      _requests = (results[2] as List<LeaveRequest>)..sort((a, b) => b.id.compareTo(a.id));
    } catch (e) {
      errorMessage = e.toString().replaceFirst('Exception: ', '');
    } finally {
      _isLoading = false;
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

  // Dung khi dang xuat de nguoi dang nhap ke tiep khong thay du lieu cua nguoi truoc.
  void clear() {
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

  String _timeLabel(LeaveRequest r) {
    switch (r.session) {
      case 'Morning':
        return 'Buổi sáng';
      case 'Afternoon':
        return 'Buổi chiều';
      case 'FullDay':
        return 'Cả ngày';
      default:
        final time = DateFormat('HH:mm');
        return '${time.format(r.startDate)} - ${time.format(r.endDate)}';
    }
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'Pending':
        return 'Chờ duyệt';
      case 'Approved':
        return 'Đã duyệt';
      case 'Rejected':
        return 'Từ chối';
      case 'Cancelled':
        return 'Đã hủy';
      default:
        return status;
    }
  }

  String _trimNumber(double value) {
    return value == value.roundToDouble() ? value.toInt().toString() : value.toString();
  }
}
