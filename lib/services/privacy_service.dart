import 'package:dio/dio.dart';

import '../core/network/api_client.dart';
import '../models/privacy.dart';

class PrivacyService {
  final ApiClient _apiClient;

  PrivacyService(this._apiClient);

  Exception _error(DioException e, String fallback) => Exception(apiErrorMessage(e, fallback));

  Future<PrivacyPolicy> getPolicy() async {
    try {
      final response = await _apiClient.dio.get('/privacy/policy');
      return PrivacyPolicy.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _error(e, 'Không tải được chính sách quyền riêng tư.');
    }
  }

  Future<PrivacyConsent> getConsent() async {
    try {
      final response = await _apiClient.dio.get('/privacy/consent');
      return PrivacyConsent.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _error(e, 'Không kiểm tra được sự đồng ý của bạn.');
    }
  }

  Future<PrivacyConsent> accept() async {
    try {
      final response = await _apiClient.dio.post('/privacy/consent');
      return PrivacyConsent.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _error(e, 'Không ghi nhận được sự đồng ý.');
    }
  }

  Future<PrivacyConsent> withdraw() async {
    try {
      final response = await _apiClient.dio.delete('/privacy/consent');
      return PrivacyConsent.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _error(e, 'Không rút lại được sự đồng ý.');
    }
  }
}
