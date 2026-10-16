import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/utils/helpers.dart';
import '../../../models/attendance_record.dart';
import '../../../models/department.dart';
import '../../../services/admin_service.dart';
import '../../../services/hr_service.dart';
import '../hr_helpers.dart';

// Chấm công toàn công ty (quyền attendance.view.all).
class HrAttendanceProvider extends ChangeNotifier {
  final HrService _service;
  final AdminService _admin;

  HrAttendanceProvider(this._service, this._admin);

  DateTime startDate = DateTime(DateTime.now().year, DateTime.now().month, 1);
  DateTime endDate = DateTime.now();
  String? departmentCode;
  String search = '';

  List<AttendanceRecord> records = [];
  List<Department> departments = [];
  bool isLoading = false;
  String? error;

  List<AttendanceRecord> get filtered {
    final q = search.trim().toLowerCase();
    if (q.isEmpty) return records;
    return records.where((r) => r.employeeName.toLowerCase().contains(q) || r.employeeCode.toLowerCase().contains(q)).toList();
  }

  Future<void> init() async {
    // Danh sách phòng ban chỉ để lọc; lỗi thì bỏ qua (vẫn xem được toàn công ty).
    try {
      departments = await _admin.getDepartments();
    } catch (_) {}
    await load();
  }

  Future<void> load({bool silent = false}) async {
    if (!silent) {
      isLoading = true;
      error = null;
      notifyListeners();
    }
    try {
      records = await _service.getAllAttendance(startDate, endDate, departmentCode: departmentCode);
    } catch (e) {
      if (!silent) error = e.toString().replaceFirst('Exception: ', '');
    }
    isLoading = false;
    notifyListeners();
  }

  Future<void> setRange(DateTime start, DateTime end) {
    startDate = start;
    endDate = end;
    return load();
  }

  Future<void> setDepartment(String? code) {
    departmentCode = code;
    return load();
  }

  void setSearch(String v) {
    search = v;
    notifyListeners();
  }

  String _csvCell(String v) => '"${v.replaceAll('"', '""')}"';

  // Xuất danh sách đang lọc ra CSV (có BOM cho Excel). Trả về null nếu thành công, ngược lại là thông báo lỗi.
  Future<String?> exportCsv() async {
    final rows = filtered;
    if (rows.isEmpty) return 'Không có dữ liệu để xuất.';
    try {
      final buf = StringBuffer('﻿');
      buf.writeln('Mã NV,Nhân viên,Ngày,Giờ vào,Giờ ra,Buổi sáng,Buổi chiều,Ghi chú sáng,Ghi chú chiều');
      for (final r in rows) {
        final d = parseDay(r.attendanceDate);
        buf.writeln([
          r.employeeCode,
          r.employeeName,
          d == null ? r.attendanceDate : isoDate(d),
          r.checkInTime == null ? '' : formatTime(r.checkInTime),
          r.checkOutTime == null ? '' : formatTime(r.checkOutTime),
          sessionStatusLabel(r.morningStatus),
          sessionStatusLabel(r.afternoonStatus),
          r.morningNote ?? '',
          r.afternoonNote ?? '',
        ].map(_csvCell).join(','));
      }
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/cham-cong-cong-ty_${isoDate(startDate)}_${isoDate(endDate)}.csv');
      await file.writeAsString(buf.toString());
      await SharePlus.instance.share(ShareParams(files: [XFile(file.path)], subject: 'Chấm công toàn công ty'));
      return null;
    } catch (e) {
      return 'Không thể xuất file CSV.';
    }
  }
}
