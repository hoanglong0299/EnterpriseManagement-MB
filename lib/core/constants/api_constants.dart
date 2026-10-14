class ApiConstants {
  static const int port = 5068;

  // Android (điện thoại thật và máy ảo) gọi localhost: lúc build, Gradle tự chạy `adb reverse tcp:5068 tcp:5068`
  // (xem adbReverseBackend trong android/app/build.gradle.kts). Muốn trỏ tới máy khác: --dart-define=API_HOST=<địa chỉ>.
  static const String _hostOverride = String.fromEnvironment('API_HOST');

  static String get baseUrl {
    if (_hostOverride.isNotEmpty) return 'http://$_hostOverride:$port/api';
    return 'http://localhost:$port/api';
  }

  static const String login = '/auth/login';
}