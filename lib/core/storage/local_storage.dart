import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../constants/app_constants.dart';

class LocalStorage {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

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

  Future<void> clear() async {
    await _storage.delete(key: AppConstants.tokenKey);
    await _storage.delete(key: AppConstants.sessionKey);
  }
}