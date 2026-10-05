import 'package:flutter/foundation.dart';

class ApiConstants {
  static const int port = 5068;

  // Điện thoại thật: chạy với --dart-define=API_HOST=localhost (kèm adb reverse tcp:5068 tcp:5068).
  static const String _hostOverride = String.fromEnvironment('API_HOST');

  static String get baseUrl {
    if (_hostOverride.isNotEmpty) return 'http://$_hostOverride:$port/api';
    final host = !kIsWeb && defaultTargetPlatform == TargetPlatform.android
        ? '10.0.2.2'
        : 'localhost';
    return 'http://$host:$port/api';
  }

  static const String login = '/auth/login';
}