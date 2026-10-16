import 'package:flutter/material.dart';

import '../../../models/admin_employee.dart';
import '../../../models/attendance_hr.dart';
import '../../../services/admin_service.dart';
import '../../../services/hr_service.dart';

// Ghi nhận chấm công ngoại lệ (quyền attendance.note.manage).
class HrNotesProvider extends ChangeNotifier {
  final HrService _service;
  final AdminService _admin;

  HrNotesProvider(this._service, this._admin);

  List<AdminEmployee> employees = [];
  List<AttendanceNote> notes = [];

  // Bộ lọc danh sách ghi chú đang hiệu lực: mặc định từ đầu tháng đến hôm nay.
  DateTime from = DateTime(DateTime.now().year, DateTime.now().month, 1);
  DateTime to = DateTime.now();
  String? employeeFilter;

  bool isLoading = false;
  bool isSaving = false;
  int? revokingId;
  String? error;

  Future<void> init() async {
    // Danh sách nhân viên lỗi thì form không chọn được người; báo qua error khi tải ghi chú xong.
    String? employeeError;
    try {
      employees = (await _admin.getEmployees()).where((e) => e.employmentStatus.toLowerCase() != 'terminated').toList();
    } catch (e) {
      employeeError = e.toString().replaceFirst('Exception: ', '');
    }
    await loadNotes();
    if (employeeError != null && error == null) error = employeeError;
    notifyListeners();
  }

  Future<void> loadNotes({bool silent = false}) async {
    if (!silent) {
      isLoading = true;
      error = null;
      notifyListeners();
    }
    try {
      notes = await _service.getNotes(from, to, employeeCode: employeeFilter);
    } catch (e) {
      if (!silent) error = e.toString().replaceFirst('Exception: ', '');
    }
    isLoading = false;
    notifyListeners();
  }

  Future<void> setRange(DateTime start, DateTime end) {
    from = start;
    to = end;
    return loadNotes();
  }

  Future<void> setEmployeeFilter(String? code) {
    employeeFilter = code;
    return loadNotes();
  }

  // Tạo ghi chú. Trả về null nếu thành công, ngược lại là message lỗi nguyên văn của backend.
  Future<String?> create({
    required String employeeCode,
    required DateTime startDate,
    required DateTime endDate,
    required String session,
    required String status,
    required String note,
  }) async {
    isSaving = true;
    notifyListeners();
    String? err;
    try {
      await _service.createNote(
        employeeCode: employeeCode,
        startDate: startDate,
        endDate: endDate,
        session: session,
        status: status,
        note: note,
      );
    } catch (e) {
      err = e.toString().replaceFirst('Exception: ', '');
    }
    isSaving = false;
    notifyListeners();
    if (err == null) await loadNotes();
    return err;
  }

  Future<String?> revoke(int id) async {
    revokingId = id;
    notifyListeners();
    String? err;
    try {
      await _service.revokeNote(id);
    } catch (e) {
      err = e.toString().replaceFirst('Exception: ', '');
    }
    revokingId = null;
    notifyListeners();
    if (err == null) await loadNotes();
    return err;
  }
}
