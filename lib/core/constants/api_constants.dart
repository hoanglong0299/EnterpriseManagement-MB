import 'package:flutter/foundation.dart';

class ApiConstants {
  static const int port = 5068;

  static String get baseUrl {
    final host = !kIsWeb && defaultTargetPlatform == TargetPlatform.android
        ? '10.0.2.2'
        : 'localhost';
    return 'http://$host:$port/api';
  }

  static const String login = '/auth/login';
}