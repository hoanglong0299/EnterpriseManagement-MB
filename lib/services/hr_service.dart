import 'package:dio/dio.dart';
import 'package:intl/intl.dart';

import '../core/network/api_client.dart';
import '../models/attendance_adjustment.dart';
import '../models/attendance_hr.dart';
import '../models/attendance_record.dart';

// Gọi các API chấm công theo buổi, ghi chú ngoại lệ, đi làm lại và xử lý điều chỉnh công (xem hợp đồng API của backend).
// Mọi lỗi nghiệp vụ trả {message} tiếng Việt, được đưa nguyên văn vào Exception.
class HrService {
  final ApiClient _apiClient;

  HrService(this._apiClient);

  static String _d(DateTime date) => DateFormat('yyyy-MM-dd').format(date);

  Exception _error(DioException e, String fallback) => Exception(apiErrorMessage(e, fallback));

  List<T> _list<T>(dynamic data, T Function(Map<String, dynamic>) parse) =>
      (data as List).map((e) => parse(e as Map<String, dynamic>)).toList();

  // ---- Lịch hiệu lực và chấm công toàn công ty ----

  Future<List<AttendanceCalendarDay>> getCalendar(String employeeCode, DateTime from, DateTime to) async {
    try {
      final response = await _apiClient.dio.get(
        '/attendance/$employeeCode/calendar',
        queryParameters: {'from': _d(from), 'to': _d(to)},
      );
      return _list(response.data, AttendanceCalendarDay.fromJson);
    } on DioException catch (e) {
      throw _error(e, 'Không tải được lịch chấm công.');
    }
  }

  // Quyền attendance.view.all. departmentCode null = toàn công ty.
  Future<List<AttendanceRecord>> getAllAttendance(DateTime start, DateTime end, {String? departmentCode}) async {
    try {
      final response = await _apiClient.dio.get('/attendance/all', queryParameters: {
        'startDate': _d(start),
        'endDate': _d(end),
        if (departmentCode != null && departmentCode.isNotEmpty) 'departmentCode': departmentCode,
      });
      return _list(response.data, AttendanceRecord.fromJson);
    } on DioException catch (e) {
      throw _error(e, 'Không tải được bảng chấm công.');
    }
  }

  // ---- Ghi chú ngoại lệ chấm công (attendance.note.manage) ----

  Future<List<AttendanceNote>> getNotes(DateTime from, DateTime to, {String? employeeCode}) async {
    try {
      final response = await _apiClient.dio.get('/attendance-notes', queryParameters: {
        'from': _d(from),
        'to': _d(to),
        if (employeeCode != null && employeeCode.isNotEmpty) 'employeeCode': employeeCode,
      });
      return _list(response.data, AttendanceNote.fromJson);
    } on DioException catch (e) {
      throw _error(e, 'Không tải được ghi chú chấm công.');
    }
  }

  // session: Morning | Afternoon | FullDay. status: OnTime | Late | Absent.
  Future<List<AttendanceNote>> createNote({
    required String employeeCode,
    required DateTime startDate,
    required DateTime endDate,
    required String session,
    required String status,
    required String note,
  }) async {
    try {
      final response = await _apiClient.dio.post('/attendance-notes', data: {
        'employeeCode': employeeCode,
        'startDate': _d(startDate),
        'endDate': _d(endDate),
        'session': session,
        'status': status,
        'note': note,
      });
      return _list(response.data, AttendanceNote.fromJson);
    } on DioException catch (e) {
      throw _error(e, 'Không ghi chú được.');
    }
  }

  Future<void> revokeNote(int id) async {
    try {
      await _apiClient.dio.delete('/attendance-notes/$id');
    } on DioException catch (e) {
      throw _error(e, 'Không thu hồi được ghi chú.');
    }
  }

  // ---- Điều chỉnh công, bước xử lý (attendance.adjustment.apply) ----

  Future<List<AttendanceAdjustment>> getAdjustmentsAwaitingProcessing() async {
    try {
      final response = await _apiClient.dio.get('/attendance/adjustments/pending-processing');
      return _list(response.data, AttendanceAdjustment.fromJson);
    } on DioException catch (e) {
      throw _error(e, 'Không tải được danh sách chờ xử lý.');
    }
  }

  Future<void> applyAdjustment(int id) async {
    try {
      await _apiClient.dio.put('/attendance/adjustments/$id/apply');
    } on DioException catch (e) {
      throw _error(e, 'Không áp dụng được yêu cầu.');
    }
  }

  Future<void> rejectAdjustmentProcessing(int id, {String? reason}) async {
    try {
      await _apiClient.dio.put('/attendance/adjustments/$id/reject-processing', data: {'rejectionReason': reason});
    } on DioException catch (e) {
      throw _error(e, 'Không từ chối được yêu cầu.');
    }
  }

  // ---- Đi làm lại ----

  // Nhân viên (leave.request.self). fromSession: Morning | Afternoon.
  Future<LeaveReturnPreview> previewReturn(DateTime fromDate, String fromSession) async {
    try {
      final response = await _apiClient.dio.get(
        '/leave-returns/preview',
        queryParameters: {'fromDate': _d(fromDate), 'fromSession': fromSession},
      );
      return LeaveReturnPreview.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _error(e, 'Không xem trước được yêu cầu rút ngắn nghỉ phép.');
    }
  }

  Future<LeaveReturnRequest> submitReturn(DateTime fromDate, String fromSession, String reason) async {
    try {
      final response = await _apiClient.dio.post(
        '/leave-returns',
        data: {'fromDate': _d(fromDate), 'fromSession': fromSession, 'reason': reason},
      );
      return LeaveReturnRequest.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _error(e, 'Không gửi được yêu cầu rút ngắn nghỉ phép.');
    }
  }

  Future<List<LeaveReturnRequest>> getMyReturns() async {
    try {
      final response = await _apiClient.dio.get('/leave-returns/mine');
      return _list(response.data, LeaveReturnRequest.fromJson);
    } on DioException catch (e) {
      throw _error(e, 'Không tải được yêu cầu rút ngắn nghỉ phép.');
    }
  }

  // Manager (leave.request.view / leave.request.approve).
  Future<List<LeaveReturnRequest>> getPendingReturns() async {
    try {
      final response = await _apiClient.dio.get('/leave-returns/pending');
      return _list(response.data, LeaveReturnRequest.fromJson);
    } on DioException catch (e) {
      throw _error(e, 'Không tải được yêu cầu rút ngắn nghỉ phép chờ duyệt.');
    }
  }

  Future<void> approveReturn(int id) async {
    try {
      await _apiClient.dio.put('/leave-returns/$id/approve');
    } on DioException catch (e) {
      throw _error(e, 'Không duyệt được yêu cầu.');
    }
  }

  Future<void> rejectReturn(int id, {String? reason}) async {
    try {
      await _apiClient.dio.put('/leave-returns/$id/reject', data: {'reason': reason});
    } on DioException catch (e) {
      throw _error(e, 'Không từ chối được yêu cầu.');
    }
  }

  // Người xử lý (attendance.note.manage).
  Future<List<LeaveReturnRequest>> getReturnsAwaitingProcessing() async {
    try {
      final response = await _apiClient.dio.get('/leave-returns/awaiting-processing');
      return _list(response.data, LeaveReturnRequest.fromJson);
    } on DioException catch (e) {
      throw _error(e, 'Không tải được yêu cầu chờ xử lý.');
    }
  }

  // items: mỗi phần tử {date: yyyy-MM-dd, session: Morning|Afternoon, status: OnTime|Late}. Buổi không có trong items mặc định OnTime.
  Future<void> processReturn(int id, List<Map<String, String>> items) async {
    try {
      await _apiClient.dio.put('/leave-returns/$id/process', data: {'items': items});
    } on DioException catch (e) {
      throw _error(e, 'Không xác nhận được yêu cầu.');
    }
  }

  Future<void> rejectReturnProcessing(int id, {String? reason}) async {
    try {
      await _apiClient.dio.put('/leave-returns/$id/reject-processing', data: {'reason': reason});
    } on DioException catch (e) {
      throw _error(e, 'Không từ chối được yêu cầu.');
    }
  }
}
