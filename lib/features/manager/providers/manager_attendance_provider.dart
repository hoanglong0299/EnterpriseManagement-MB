import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/utils/helpers.dart';
import '../../../models/manager_attendance.dart';
import '../../../services/manager_service.dart';
import '../../auth/providers/auth_provider.dart';
import '../manager_helpers.dart';

class ManagerAttendanceProvider extends ChangeNotifier {
  final ManagerService _service;
  final AuthProvider _auth;

  ManagerAttendanceProvider(this._service, this._auth);

  // Mặc định: từ đầu tháng đến hôm nay (giống web).
  DateTime startDate = DateTime(DateTime.now().year, DateTime.now().month, 1);
  DateTime endDate = DateTime.now();
  String? employeeFilter; // employeeCode
  String? statusFilter;

  String? _departmentCode;
  List<ManagerAttendanceRecord> records = [];
  List<ManagerAttendanceAdjustment> pending = [];

  bool isLoadingTeam = false;
  bool isLoadingPending = false;
  String? teamError;
  String? pendingError;
  int? busyId;

  // Danh sách nhân viên xuất hiện trong bảng công để lọc theo người.
  Map<String, String> get employeeOptions {
    final map = <String, String>{};
    for (final r in records) {
      map[r.employeeCode] = r.employeeName;
    }
    return map;
  }

  List<ManagerAttendanceRecord> get filteredRecords => records.where((r) {
        if (employeeFilter != null && r.employeeCode != employeeFilter) return false;
        if (statusFilter != null && r.status != statusFilter) return false;
        return true;
      }).toList();

  Future<void> setRange(DateTime start, DateTime end) async {
    startDate = start;
    endDate = end;
    await loadTeam();
  }

  void setEmployee(String? v) {
    employeeFilter = v;
    notifyListeners();
  }

  void setStatus(String? v) {
    statusFilter = v;
    notifyListeners();
  }

  Future<void> loadTeam() async {
    isLoadingTeam = true;
    teamError = null;
    notifyListeners();
    try {
      if (_departmentCode == null || _departmentCode!.isEmpty) {
        final code = _auth.session?.employeeCode;
        if (code == null) throw Exception('Tài khoản chưa gắn với nhân viên nào.');
        _departmentCode = await _service.getDepartmentCodeOf(code);
      }
      records = await _service.getDepartmentAttendance(_departmentCode!, isoDate(startDate), isoDate(endDate));
      // Nhân viên đang lọc không còn trong kết quả mới thì bỏ lọc.
      if (employeeFilter != null && !employeeOptions.containsKey(employeeFilter)) employeeFilter = null;
    } catch (e) {
      teamError = e.toString().replaceFirst('Exception: ', '');
    }
    isLoadingTeam = false;
    notifyListeners();
  }

  Future<void> loadPending() async {
    isLoadingPending = true;
    pendingError = null;
    notifyListeners();
    try {
      pending = await _service.getPendingAdjustments();
    } catch (e) {
      pendingError = e.toString().replaceFirst('Exception: ', '');
    }
    isLoadingPending = false;
    notifyListeners();
  }

  // Duyệt/từ chối yêu cầu điều chỉnh. Trả về null nếu thành công, ngược lại là thông báo lỗi.
  Future<String?> review(int id, {required bool approve}) async {
    busyId = id;
    notifyListeners();
    String? error;
    try {
      if (approve) {
        await _service.approveAdjustment(id);
      } else {
        await _service.rejectAdjustment(id);
      }
    } catch (e) {
      error = e.toString().replaceFirst('Exception: ', '');
    }
    busyId = null;
    notifyListeners();
    if (error == null) await loadPending();
    return error;
  }

  String _csvCell(String v) => '"${v.replaceAll('"', '""')}"';

  // Xuất bảng công đang lọc ra CSV (có BOM để Excel đọc đúng tiếng Việt) rồi mở khung chia sẻ.
  // Trả về null nếu thành công, ngược lại là thông báo lỗi.
  Future<String?> exportCsv() async {
    final rows = filteredRecords;
    if (rows.isEmpty) return 'Không có dữ liệu để xuất.';
    try {
      final buf = StringBuffer('﻿');
      buf.writeln('Mã NV,Nhân viên,Ngày,Giờ vào,Giờ ra,Giờ làm,Trạng thái');
      for (final r in rows) {
        buf.writeln([
          r.employeeCode,
          r.employeeName,
          isoDate(r.attendanceDate),
          r.checkInTime == null ? '' : formatDateTime(r.checkInTime),
          r.checkOutTime == null ? '' : formatDateTime(r.checkOutTime),
          r.workingHours?.toString() ?? '',
          attendanceLabels[r.status] ?? r.status,
        ].map(_csvCell).join(','));
      }
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/bang-cong_${isoDate(startDate)}_${isoDate(endDate)}.csv');
      await file.writeAsString(buf.toString());
      await SharePlus.instance.share(ShareParams(files: [XFile(file.path)], subject: 'Bảng công team'));
      return null;
    } catch (e) {
      return 'Không thể xuất file CSV.';
    }
  }
}
