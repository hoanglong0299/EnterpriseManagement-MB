import 'package:dio/dio.dart';
import '../core/constants/api_constants.dart';
import '../core/network/api_client.dart';
import '../models/check_in_record.dart';

class CheckInService {
  final ApiClient _apiClient = ApiClient();

  Future<bool> submitCheckIn(CheckInRecord record) async {
    try {
      final response = await _apiClient.client.post(
        ApiConstants.checkIn,
        data: record.toJson(),
      );

      return (response.statusCode == 200 || response.statusCode == 201);
    } on DioException catch (e) {
      String errorMessage = 'Lỗi kết nối máy chủ khi chấm công.';
      if (e.response?.data != null && e.response?.data is Map) {
        errorMessage = e.response?.data['message'] ?? errorMessage;
      }
      throw Exception(errorMessage);
    }
  }
}