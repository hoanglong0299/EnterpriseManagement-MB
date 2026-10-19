import 'package:dio/dio.dart';
import 'package:intl/intl.dart';

import '../core/network/api_client.dart';
import '../models/overtime.dart';

// Xin làm thêm giờ (OT): nhân viên gửi/hủy, quản lý duyệt. Lỗi nghiệp vụ là {message} tiếng Việt, đưa nguyên văn vào Exception.
class OvertimeService {
  final ApiClient _apiClient;

  OvertimeService(this._apiClient);

  Exception _error(DioException e, String fallback) => Exception(apiErrorMessage(e, fallback));

  List<OvertimeRequest> _list(dynamic data) =>
      (data as List).map((e) => OvertimeRequest.fromJson(e as Map<String, dynamic>)).toList();

  static String _time(int hour, int minute) =>
      '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';

  Future<List<OvertimeRequest>> getMine() async {
    try {
      return _list((await _apiClient.dio.get('/overtime-requests/mine')).data);
    } on DioException catch (e) {
      throw _error(e, 'Không tải được đơn làm thêm giờ.');
    }
  }

  Future<OvertimeQuota> getQuota() async {
    try {
      final response = await _apiClient.dio.get('/overtime-requests/quota');
      return OvertimeQuota.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _error(e, 'Không tải được hạn mức làm thêm giờ.');
    }
  }

  Future<OvertimeRequest> submit({
    required DateTime date,
    required int startHour,
    required int startMinute,
    required int endHour,
    required int endMinute,
    required String reason,
  }) async {
    try {
      final response = await _apiClient.dio.post('/overtime-requests', data: {
        'date': DateFormat('yyyy-MM-dd').format(date),
        'startTime': _time(startHour, startMinute),
        'endTime': _time(endHour, endMinute),
        'reason': reason,
      });
      return OvertimeRequest.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _error(e, 'Không gửi được đơn làm thêm giờ.');
    }
  }

  Future<void> cancel(int id) async {
    try {
      await _apiClient.dio.put('/overtime-requests/$id/cancel');
    } on DioException catch (e) {
      throw _error(e, 'Không hủy được đơn.');
    }
  }

  // ---- Quản lý (overtime.request.view / overtime.request.approve) ----

  Future<List<OvertimeRequest>> getPending() async {
    try {
      return _list((await _apiClient.dio.get('/overtime-requests/pending')).data);
    } on DioException catch (e) {
      throw _error(e, 'Không tải được đơn chờ duyệt.');
    }
  }

  Future<List<OvertimeRequest>> getHistory() async {
    try {
      return _list((await _apiClient.dio.get('/overtime-requests/history')).data);
    } on DioException catch (e) {
      throw _error(e, 'Không tải được lịch sử đơn.');
    }
  }

  Future<void> approve(int id) async {
    try {
      await _apiClient.dio.put('/overtime-requests/$id/approve');
    } on DioException catch (e) {
      throw _error(e, 'Không duyệt được đơn.');
    }
  }

  Future<void> reject(int id, String? reason) async {
    try {
      await _apiClient.dio.put('/overtime-requests/$id/reject', data: {'rejectionReason': reason});
    } on DioException catch (e) {
      throw _error(e, 'Không từ chối được đơn.');
    }
  }
}
