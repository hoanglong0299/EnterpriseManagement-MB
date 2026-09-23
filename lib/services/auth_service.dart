import 'package:dio/dio.dart';

import '../core/network/api_client.dart';
import '../models/user.dart';

class AuthService {
  final ApiClient _apiClient;

  AuthService(this._apiClient);

  Future<AuthSession> login(String username, String password) async {
    try {
      final response = await _apiClient.dio.post(
        '/auth/login',
        data: {'username': username, 'password': password},
      );
      return AuthSession.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      final message = e.response?.data is Map
          ? (e.response?.data['message'] as String? ?? 'Đăng nhập thất bại.')
          : 'Đăng nhập thất bại.';
      throw Exception(message);
    }
  }
}