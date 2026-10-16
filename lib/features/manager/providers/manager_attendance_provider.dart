import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/utils/helpers.dart';
import '../../../models/manager_attendance.dart';
import '../../../models/manager_employee.dart';
import '../../../services/manager_service.dart';
import '../../auth/providers/auth_provider.dart';
import '../manager_helpers.dart';

class ManagerAttendanceProvider extends ChangeNotifier {
  final ManagerService _service;
  final AuthProvider _auth;

  ManagerAttendanceProvider(this._service, this._auth);

  // Mặc định: chỉ hôm nay (giống web); muốn xem khoảng khác thì chọn khoảng ngày.
  DateTime startDate = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
  DateTime endDate = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
  String? employeeFilter; // employeeCode
  String? statusFilter;

  List<ManagerAttendanceRecord> records = [];
  List<ManagerAttendanceAdjustment> pending = [];

  bool isLoadingTeam = false;
  bool isLoadingPending = false;
  String? teamError;
  String? pendingError;
  int? busyId;

  // Toàn bộ cấp dưới của quản lý (không phụ thuộc ngày đang xem), dùng cho ô chọn nhân viên.
  List<ManagerEmployee> teamMembers = [];

  // Ô chọn nhân viên: mọi cấp dưới còn làm việc, kể cả người chưa có dòng chấm công trong khoảng ngày.
  Map<String, String> get employeeOptions {
    final map = <String, String>{};
    for (final e in teamMembers) {
      if (e.employmentStatus == 'Resigned' || e.employmentStatus == 'Terminated') continue;
      map[e.employeeCode] = e.fullName;
    }
    // Phòng khi API cấp dưới chưa tải được: vẫn cho lọc theo người có trong bảng công.
    for (final r in records) {
      map.putIfAbsent(r.employeeCode, () => r.employeeName);
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

  Future<void> loadTeam({bool silent = false}) async {
    if (!silent) {
      isLoadingTeam = true;
      teamError = null;
      notifyListeners();
    }
    try {
      final code = _auth.session?.employeeCode;
      if (code == null) throw Exception('Tài khoản chưa gắn với nhân viên nào.');
      // Danh sách là cấp dưới mà người này quản lý (đệ quy), không phải mọi người cùng phòng ban.
      if (teamMembers.isEmpty) {
        try {
          teamMembers = await _service.getTeamRecursive(code);
        } catch (_) {
          // Không tải được danh sách thì ô chọn tạm dùng người có trong bảng công.
        }
      }
      records = await _service.getTeamAttendance(code, isoDate(startDate), isoDate(endDate));
      // Nhân viên đang lọc không còn trong kết quả mới thì bỏ lọc.
      if (employeeFilter != null && !employeeOptions.containsKey(employeeFilter)) employeeFilter = null;
    } catch (e) {
      if (!silent) teamError = e.toString().replaceFirst('Exception: ', '');
    }
    isLoadingTeam = false;
    notifyListeners();
  }

  Future<void> loadPending({bool silent = false}) async {
    if (!silent) {
      isLoadingPending = true;
      pendingError = null;
      notifyListeners();
    }
    try {
      pending = await _service.getPendingAdjustments();
    } catch (e) {
      if (!silent) pendingError = e.toString().replaceFirst('Exception: ', '');
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
