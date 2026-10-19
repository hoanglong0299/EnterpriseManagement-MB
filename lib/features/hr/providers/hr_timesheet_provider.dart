import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../../models/timesheet.dart';
import '../../../services/timesheet_service.dart';

// Bảng công tháng của HR (quyền timesheet.manage): tổng hợp theo nhân viên, chốt/mở lại kỳ công, xuất CSV.
class HrTimesheetProvider extends ChangeNotifier {
  final TimesheetService _service;

  // Bảng công của team (quản lý chỉ xem) thay vì toàn công ty.
  final bool team;

  HrTimesheetProvider(this._service, {this.team = false}) {
    // Mở màn hình ở tháng gần nhất đã kết thúc (tháng trước), vì chỉ chốt được tháng đã qua.
    final now = DateTime.now();
    final previous = DateTime(now.year, now.month - 1);
    year = previous.year;
    month = previous.month;
  }

  late int year;
  late int month;
  Timesheet? sheet;
  bool isLoading = false;
  bool isBusy = false;
  String? error;
  String search = '';

  bool get isCurrentOrFuture {
    final now = DateTime.now();
    return year > now.year || (year == now.year && month >= now.month);
  }

  List<TimesheetRow> get filtered {
    final rows = sheet?.rows ?? const <TimesheetRow>[];
    final q = search.trim().toLowerCase();
    if (q.isEmpty) return rows;
    return rows.where((r) => r.employeeName.toLowerCase().contains(q) || r.employeeCode.toLowerCase().contains(q)).toList();
  }

  Future<void> load({bool silent = false}) async {
    if (!silent) {
      isLoading = true;
      error = null;
      notifyListeners();
    }
    try {
      sheet = await _service.getTimesheet(year, month, team: team);
    } catch (e) {
      if (!silent) error = e.toString().replaceFirst('Exception: ', '');
    }
    isLoading = false;
    notifyListeners();
  }

  Future<void> shiftMonth(int delta) {
    final d = DateTime(year, month + delta);
    year = d.year;
    month = d.month;
    sheet = null;
    return load();
  }

  void setSearch(String v) {
    search = v;
    notifyListeners();
  }

  // null = thành công, ngược lại là thông báo lỗi nguyên văn.
  Future<String?> close() => _run(() => _service.closePeriod(year, month));

  Future<String?> reopen() => _run(() => _service.reopenPeriod(year, month));

  Future<String?> _run(Future<void> Function() action) async {
    isBusy = true;
    notifyListeners();
    String? err;
    try {
      await action();
    } catch (e) {
      err = e.toString().replaceFirst('Exception: ', '');
    }
    isBusy = false;
    notifyListeners();
    await load(silent: true);
    return err;
  }

  String _csvCell(String v) => '"${v.replaceAll('"', '""')}"';

  // Xuất bảng công đang xem ra CSV (có BOM cho Excel). Trả về null nếu thành công, ngược lại là thông báo lỗi.
  Future<String?> exportCsv() async {
    final data = sheet;
    if (data == null || data.rows.isEmpty) return 'Không có dữ liệu để xuất.';
    try {
      final buf = StringBuffer('﻿');
      buf.writeln('Bảng công tháng ${month.toString().padLeft(2, '0')}/$year,${data.isClosed ? 'Đã chốt' : 'Chưa chốt'},Công chuẩn ${data.standardDays} ngày');
      buf.writeln('Mã NV,Họ tên,Phòng ban,Ngày công đi làm,Ngày nghỉ phép,Ngày vắng,Số buổi đi muộn,Giờ làm thêm');
      for (final r in data.rows) {
        buf.writeln([
          r.employeeCode,
          r.employeeName,
          r.departmentName,
          r.workedDays.toString(),
          r.leaveDays.toString(),
          r.absentDays.toString(),
          r.lateSessions.toString(),
          r.overtimeHours.toString(),
        ].map(_csvCell).join(','));
      }
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/bang-cong-$year-${month.toString().padLeft(2, '0')}.csv');
      await file.writeAsString(buf.toString());
      await SharePlus.instance.share(ShareParams(files: [XFile(file.path)], subject: 'Bảng công tháng $month/$year'));
      return null;
    } catch (e) {
      return 'Không thể xuất file CSV.';
    }
  }
}
