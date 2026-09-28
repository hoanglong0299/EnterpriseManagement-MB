import 'package:dio/dio.dart';

import '../core/network/api_client.dart';
import '../models/attendance_record.dart';

class AttendanceService {
  final ApiClient _apiClient;

  AttendanceService(this._apiClient);

  Future<AttendanceRecord> punch() async {
    try {
      final response = await _apiClient.dio.post('/attendance/punch');
      return AttendanceRecord.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw Exception(_message(e));
    }
  }

  Future<List<AttendanceRecord>> getHistory(String employeeCode) async {
    try {
      final response = await _apiClient.dio.get('/attendance/$employeeCode/history');
      final list = response.data as List;
      return list
          .map((item) => AttendanceRecord.fromJson(item as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw Exception(_message(e));
    }
  }

  String _message(DioException e) {
    return e.response?.data is Map
        ? (e.response?.data['message'] as String? ?? 'Khong the cham cong.')
        : 'Khong the cham cong.';
  }
}
