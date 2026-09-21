import 'package:shared_preferences/shared_preferences.dart';

class LocalStorage {
  // Đặt tên key để lưu trong bộ nhớ
  static const String _tokenKey = 'auth_token';
  // (Tùy chọn) Bạn có thể lưu thêm ID hoặc Tên nhân viên nếu cần
  static const String _userIdKey = 'user_id'; 

  // 1. Hàm LƯU Token (Gọi khi Đăng nhập thành công)
  static Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
  }

  // 2. Hàm ĐỌC Token (Gọi bởi ApiClient hoặc lúc mở app)
  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey); // Sẽ trả về null nếu chưa từng lưu
  }

  // 3. Hàm XÓA Token (Gọi khi nhân viên Đăng xuất)
  static Future<void> removeToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    // Nếu có lưu userId thì xóa luôn: await prefs.remove(_userIdKey);
  }

  // (Tùy chọn) Hàm kiểm tra xem đã đăng nhập chưa
  static Future<bool> hasToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey(_tokenKey);
  }
}