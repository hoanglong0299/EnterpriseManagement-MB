import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../models/attendance_record.dart';
import '../../../services/attendance_service.dart';
import '../../auth/providers/auth_provider.dart';

class CheckInProvider extends ChangeNotifier {
  final AttendanceService _attendanceService;
  final AuthProvider _authProvider;

  CheckInProvider(this._attendanceService, this._authProvider);

  bool _isLoading = false;
  AttendanceRecord? _today;
  String? errorMessage;

  bool get isLoading => _isLoading;

  // Dang trong ca lam: da check-in nhung chua check-out.
  bool get hasClockedIn =>
      _today?.checkInTime != null && _today?.checkOutTime == null;

  // Man hinh chi hien thi List<String>, nen tu day chuyen AttendanceRecord
  // cua hom nay thanh danh sach chuoi, moi nhat hien truoc (giong du lieu gia truoc day).
  List<String> get historyRecords {
    final record = _today;
    if (record == null) return [];

    final list = <String>[];
    if (record.checkOutTime != null) {
      list.add(
        '${DateFormat('HH.mm').format(record.checkOutTime!)} at Company (OUT)',
      );
    }
    if (record.checkInTime != null) {
      list.add(
        '${DateFormat('HH.mm').format(record.checkInTime!)} at Company (IN)',
      );
    }
    return list;
  }

  Future<void> loadToday() async {
    final employeeCode = _authProvider.session?.employeeCode;
    if (employeeCode == null) return;

    try {
      final history = await _attendanceService.getHistory(employeeCode);
      final todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
      final matches = history.where((r) => r.attendanceDate == todayStr);
      _today = matches.isEmpty ? null : matches.first;
    } catch (e) {
      errorMessage = e.toString().replaceFirst('Exception: ', '');
    }
    notifyListeners();
  }

  Future<void> performAction(String actionType) async {
    _isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      _today = await _attendanceService.punch();
    } catch (e) {
      errorMessage = e.toString().replaceFirst('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
