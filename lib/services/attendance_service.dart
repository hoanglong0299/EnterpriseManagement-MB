import 'dart:typed_data';

import 'package:dio/dio.dart';

import '../core/network/api_client.dart';
import '../models/attendance_record.dart';
import '../models/office_location.dart';

class AttendanceService {
  final ApiClient _apiClient;

  AttendanceService(this._apiClient);

  // Backend tự quyết định đây là check-in hay check-out của hôm nay, và chỉ nhận khi đang trong bán kính
  // cho phép quanh công ty. Vị trí + ảnh được lưu lại làm bằng chứng cho lần chấm công này.
  Future<AttendanceRecord> punch({
    required double latitude,
    required double longitude,
    required bool isMockLocation,
    Uint8List? photoBytes,
  }) async {
    try {
      // Toạ độ gửi dạng chuỗi (Dart luôn dùng dấu "." thập phân, không phụ thuộc ngôn ngữ máy).
      final formData = FormData.fromMap({
        'latitude': latitude.toString(),
        'longitude': longitude.toString(),
        'isMockLocation': isMockLocation.toString(),
        // Chỉ check-in mới gửi ảnh; check-out không cần.
        if (photoBytes != null)
          'photo': MultipartFile.fromBytes(
            photoBytes,
            filename: 'attendance.jpg',
            contentType: DioMediaType('image', 'jpeg'),
          ),
      });
      final response = await _apiClient.dio.post('/attendance/punch', data: formData);
      return AttendanceRecord.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw Exception(_message(e));
    }
  }

  Future<OfficeLocation> getOfficeLocation() async {
    try {
      final response = await _apiClient.dio.get('/attendance/office-location');
      return OfficeLocation.fromJson(response.data as Map<String, dynamic>);
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

  String _message(DioException e) => apiErrorMessage(e, 'Không thể xử lý yêu cầu chấm công.');
}
