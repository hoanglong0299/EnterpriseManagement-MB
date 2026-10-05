import 'package:dio/dio.dart';

import '../core/network/api_client.dart';

// Thao tác tài khoản của chính người đang đăng nhập (giống trang "Cài đặt tài khoản" bên web).
class AccountService {
  final ApiClient _apiClient;

  AccountService(this._apiClient);

  // POST /auth/change-password: chỉ cần đăng nhập. Sai mật khẩu hiện tại thì backend trả 400 kèm message.
  Future<void> changePassword({required String currentPassword, required String newPassword}) async {
    try {
      await _apiClient.dio.post(
        '/auth/change-password',
        data: {'currentPassword': currentPassword, 'newPassword': newPassword},
      );
    } on DioException catch (e) {
      throw Exception(apiErrorMessage(e, 'Không thể đổi mật khẩu.'));
    }
  }
}
