import 'package:dio/dio.dart';

import '../core/network/api_client.dart';
import '../models/leave_balance.dart';
import '../models/leave_request.dart';
import '../models/leave_type.dart';

class LeaveService {
  final ApiClient _apiClient;

  LeaveService(this._apiClient);

  Future<List<LeaveType>> getTypes() async {
    try {
      final response = await _apiClient.dio.get('/leave-types');
      return (response.data as List)
          .map((item) => LeaveType.fromJson(item as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw Exception(_message(e));
    }
  }

  Future<List<LeaveBalance>> getBalances(String employeeCode, int year) async {
    try {
      final response = await _apiClient.dio.get(
        '/leave-balances/$employeeCode',
        queryParameters: {'year': year},
      );
      return (response.data as List)
          .map((item) => LeaveBalance.fromJson(item as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw Exception(_message(e));
    }
  }

  Future<List<LeaveRequest>> getMyRequests() async {
    try {
      final response = await _apiClient.dio.get('/leave-requests/mine');
      return (response.data as List)
          .map((item) => LeaveRequest.fromJson(item as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw Exception(_message(e));
    }
  }

  Future<LeaveRequest> submit({
    required String leaveTypeCode,
    required DateTime startDate,
    required DateTime endDate,
    required String session,
    required String reason,
  }) async {
    try {
      final response = await _apiClient.dio.post(
        '/leave-requests',
        data: {
          'leaveTypeCode': leaveTypeCode,
          'startDate': _dateOnly(startDate),
          'endDate': _dateOnly(endDate),
          'session': session,
          'reason': reason,
        },
      );
      return LeaveRequest.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw Exception(_message(e));
    }
  }

  // Nghỉ ngắn: gửi nguyên giờ bắt đầu/kết thúc của khung 30 phút (backend chỉ nhận khung hợp lệ trong hôm nay).
  Future<LeaveRequest> submitShort({
    required String leaveTypeCode,
    required DateTime start,
    required DateTime end,
    required String reason,
  }) async {
    try {
      final response = await _apiClient.dio.post(
        '/leave-requests',
        data: {
          'leaveTypeCode': leaveTypeCode,
          'startDate': _dateTime(start),
          'endDate': _dateTime(end),
          'reason': reason,
        },
      );
      return LeaveRequest.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw Exception(_message(e));
    }
  }

  Future<LeaveRequest> cancel(int id) async {
    try {
      final response = await _apiClient.dio.put('/leave-requests/$id/cancel');
      return LeaveRequest.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw Exception(_message(e));
    }
  }

  // Cac API duoi day chi quan ly (hoac admin) goi duoc, nhan vien thuong se bi 403.
  Future<List<LeaveRequest>> getPending() => _getList('/leave-requests/pending');

  Future<List<LeaveRequest>> getHistory() => _getList('/leave-requests/history');

  Future<LeaveRequest> approve(int id) async {
    try {
      final response = await _apiClient.dio.put('/leave-requests/$id/approve');
      return LeaveRequest.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw Exception(_message(e));
    }
  }

  Future<LeaveRequest> reject(int id, String? rejectionReason) async {
    try {
      final response = await _apiClient.dio.put(
        '/leave-requests/$id/reject',
        data: {'rejectionReason': rejectionReason},
      );
      return LeaveRequest.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw Exception(_message(e));
    }
  }

  Future<List<LeaveRequest>> _getList(String path) async {
    try {
      final response = await _apiClient.dio.get(path);
      return (response.data as List)
          .map((item) => LeaveRequest.fromJson(item as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw Exception(_message(e));
    }
  }

  // Backend chi dung phan ngay cua gia tri nay (gio duoc gan theo buoi nghi), nen gui 00:00:00.
  String _dateOnly(DateTime value) {
    final month = value.month.toString().padLeft(2, '0');
    final day = value.day.toString().padLeft(2, '0');
    return '${value.year}-$month-${day}T00:00:00';
  }

  String _dateTime(DateTime value) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${value.year}-${two(value.month)}-${two(value.day)}T${two(value.hour)}:${two(value.minute)}:00';
  }

  String _message(DioException e) => apiErrorMessage(e, 'Không thể xử lý yêu cầu nghỉ phép.');
}
