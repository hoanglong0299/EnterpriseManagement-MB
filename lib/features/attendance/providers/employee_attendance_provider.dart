import 'dart:io';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/utils/helpers.dart';
import '../../../models/attendance_adjustment.dart';
import '../../../models/attendance_record.dart';
import '../../../services/attendance_service.dart';
import '../../auth/providers/auth_provider.dart';
import '../widgets/attendance_status.dart';

class EmployeeAttendanceProvider extends ChangeNotifier {
  final AttendanceService _service;
  final AuthProvider _auth;

  EmployeeAttendanceProvider(this._service, this._auth);

  bool isLoading = false;
  String? errorMessage;
  List<AttendanceRecord> _history = [];
  List<AttendanceAdjustment> _adjustments = [];

  // Bộ lọc danh sách: theo trạng thái và theo tháng (null = tất cả).
  String? statusFilter;
  DateTime? monthFilter;

  List<AttendanceAdjustment> get adjustments => _adjustments;

  // Lịch sử mới nhất lên đầu, áp dụng bộ lọc.
  List<AttendanceRecord> get filteredHistory {
    final list = _history.where((r) {
      if (statusFilter != null && r.status != statusFilter) return false;
      final m = monthFilter;
      if (m != null) {
        final d = DateTime.parse(r.attendanceDate);
        if (d.year != m.year || d.month != m.month) return false;
      }
      return true;
    }).toList();
    list.sort((a, b) => b.attendanceDate.compareTo(a.attendanceDate));
    return list;
  }

  Map<String, AttendanceRecord> get recordsByDate => {for (final r in _history) r.attendanceDate: r};

  AttendanceRecord? get today => recordsByDate[isoDate(DateTime.now())];

  // Tổng giờ làm của các bản ghi đang hiển thị.
  double get totalHours => filteredHistory.fold(0.0, (s, r) => s + (r.workingHours ?? 0));

  void setStatusFilter(String? value) {
    statusFilter = value;
    notifyListeners();
  }

  void setMonthFilter(DateTime? value) {
    monthFilter = value;
    notifyListeners();
  }

  Future<void> load() async {
    final code = _auth.session?.employeeCode;
    if (code == null) {
      errorMessage = 'Tài khoản chưa gắn hồ sơ nhân viên. Liên hệ Admin để được liên kết.';
      notifyListeners();
      return;
    }
    // Chỉ hiện vòng quay toàn màn hình ở lần tải đầu; các lần làm mới sau giữ nguyên nội dung cũ.
    isLoading = _history.isEmpty;
    errorMessage = null;
    notifyListeners();
    try {
      _history = await _service.getHistory(code);
      // Yêu cầu điều chỉnh chỉ gọi khi có quyền (endpoint cần attendance.adjustment.self).
      _adjustments = _auth.can('attendance.adjustment.self') ? await _service.getMyAdjustments() : [];
    } catch (e) {
      errorMessage = e.toString().replaceFirst('Exception: ', '');
    }
    isLoading = false;
    notifyListeners();
  }

  // Gửi yêu cầu điều chỉnh; trả về null nếu thành công, ngược lại là thông báo lỗi.
  Future<String?> submitAdjustment({
    required DateTime date,
    required String reason,
    TimeOfDay? checkIn,
    TimeOfDay? checkOut,
  }) async {
    String? stamp(TimeOfDay? t) => t == null
        ? null
        : '${isoDate(date)}T${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}:00';
    try {
      await _service.submitAdjustment(
        attendanceDate: isoDate(date),
        reason: reason,
        newCheckInTime: stamp(checkIn),
        newCheckOutTime: stamp(checkOut),
      );
    } catch (e) {
      return e.toString().replaceFirst('Exception: ', '');
    }
    await load();
    return null;
  }

  String _csvCell(String v) => '"${v.replaceAll('"', '""')}"';

  // Xuất các bản ghi đang lọc ra CSV (có BOM để Excel đọc đúng tiếng Việt) rồi mở khung chia sẻ.
  // Trả về null nếu thành công, ngược lại là thông báo lỗi.
  Future<String?> exportCsv() async {
    final rows = filteredHistory;
    if (rows.isEmpty) return 'Không có dữ liệu để xuất.';
    try {
      final buf = StringBuffer('﻿');
      buf.writeln('Ngày,Giờ vào,Giờ ra,Số giờ làm,Trạng thái');
      for (final r in rows) {
        buf.writeln([
          formatDate(DateTime.parse(r.attendanceDate)),
          formatDateTime(r.checkInTime),
          formatDateTime(r.checkOutTime),
          r.workingHours?.toStringAsFixed(2) ?? '',
          attendanceLabel(r.status),
        ].map(_csvCell).join(','));
      }
      final dir = await getTemporaryDirectory();
      final stamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final file = File('${dir.path}/cham_cong_$stamp.csv');
      await file.writeAsString(buf.toString());
      await SharePlus.instance.share(ShareParams(files: [XFile(file.path)], subject: 'Lịch sử chấm công'));
      return null;
    } catch (e) {
      return 'Không thể xuất file CSV.';
    }
  }
}
