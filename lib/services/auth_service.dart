import 'package:dio/dio.dart';
import '../core/constants/api_constants.dart';
import '../core/network/api_client.dart';
import '../models/user.dart';

class AuthService {
  final ApiClient _apiClient = ApiClient();

  Future<UserModel> login(String username, String password) async {
    try {
      final response = await _apiClient.client.post(
        ApiConstants.login,
        data: {
          'username': username,
          'password': password,
        },
      );

      print('==== DỮ LIỆU API TRẢ VỀ ====');
      print(response.data);
      print('=============================');

      if (response.statusCode == 200 || response.statusCode == 201) {
        // Backend cần trả về dữ liệu có chứa token và thông tin user
        return UserModel.fromJson(response.data);
      } else {
        throw Exception('Đăng nhập thất bại từ phía máy chủ');
      }
    } on DioException catch (e) {
      String errorMessage = 'Kết nối tới máy chủ thất bại';
      if (e.response != null && e.response?.data != null) {
        // Lấy thông báo lỗi từ phía Backend trả về (nếu có)
        errorMessage = e.response?.data['message'] ?? 'Tài khoản hoặc mật khẩu không chính xác';
      }
      throw Exception(errorMessage);
    }
  }
}