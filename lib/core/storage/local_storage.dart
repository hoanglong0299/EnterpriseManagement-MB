import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../constants/app_constants.dart';

class LocalStorage {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  static const _rememberUsernameKey = 'remember_username';
  static const _rememberPasswordKey = 'remember_password';

  Future<void> saveSession(Map<String, dynamic> session) async {
    await _storage.write(key: AppConstants.tokenKey, value: session['token'] as String);
    await _storage.write(key: AppConstants.sessionKey, value: jsonEncode(session));
  }

  Future<String?> readToken() {
    return _storage.read(key: AppConstants.tokenKey);
  }

  Future<Map<String, dynamic>?> readSession() async {
    final raw = await _storage.read(key: AppConstants.sessionKey);
    if (raw == null) return null;
    return jsonDecode(raw) as Map<String, dynamic>;
  }

  // Thông tin "Ghi nhớ đăng nhập" lưu riêng, nên đăng xuất (clear) không xoá nó.
  Future<void> saveCredentials(String username, String password) async {
    await _storage.write(key: _rememberUsernameKey, value: username);
    await _storage.write(key: _rememberPasswordKey, value: password);
  }

  Future<({String username, String password})?> readCredentials() async {
    final username = await _storage.read(key: _rememberUsernameKey);
    final password = await _storage.read(key: _rememberPasswordKey);
    if (username == null || password == null) return null;
    return (username: username, password: password);
  }

  Future<void> clearCredentials() async {
    await _storage.delete(key: _rememberUsernameKey);
    await _storage.delete(key: _rememberPasswordKey);
  }

  Future<void> clear() async {
    await _storage.delete(key: AppConstants.tokenKey);
    await _storage.delete(key: AppConstants.sessionKey);
  }
}