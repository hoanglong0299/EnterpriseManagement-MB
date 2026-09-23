import '../models/user.dart';

class AuthService {
  Future<UserModel> login(String username, String password) async {
    // 1. Giả lập thời gian chờ máy chủ phản hồi (1.5 giây)
    await Future.delayed(const Duration(milliseconds: 1500));

    // 2. Hard code tài khoản đăng nhập thành công
    if (username == 'admin' && password == '123456') {
      return UserModel(
        id: 'EMP001',
        name: 'Nguyễn Văn A',
        token: 'fake_jwt_token_1234567890',
      );
    } else {
      // Giả lập báo lỗi nếu nhập sai
      throw Exception('Tài khoản hoặc mật khẩu không đúng (Gợi ý: admin / 123456)');
    }
  }
}