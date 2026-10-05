import 'package:flutter/foundation.dart';

import '../../../core/storage/local_storage.dart';
import '../../../models/user.dart';
import '../../../services/auth_service.dart';

enum AuthStatus { unknown, loading, authenticated, unauthenticated }

class AuthProvider extends ChangeNotifier {
  final AuthService _authService;
  final LocalStorage _storage;

  AuthProvider(this._authService, this._storage);

  AuthStatus status = AuthStatus.unknown;
  AuthSession? session;
  String? errorMessage;

  // Tài khoản có được làm hành động này không (mã permission, vd 'leave.request.approve').
  // ADMIN luôn có mọi quyền, giống PermissionAuthorizationHandler ở backend. Backend vẫn là nơi chặn thật.
  bool can(String permission) {
    final s = session;
    if (s == null) return false;
    return s.roles.contains('ADMIN') || s.permissions.contains(permission);
  }

  Future<void> restoreSession() async {
    final saved = await _storage.readSession();
    // Phiên lưu từ bản cũ chưa có danh sách permission: bắt đăng nhập lại để lấy quyền từng hành động.
    if (saved == null || saved['permissions'] == null) {
      if (saved != null) await _storage.clear();
      status = AuthStatus.unauthenticated;
    } else {
      session = AuthSession.fromJson(saved);
      status = AuthStatus.authenticated;
    }
    notifyListeners();
  }

  Future<void> login(String username, String password) async {
    status = AuthStatus.loading;
    errorMessage = null;
    notifyListeners();

    try {
      final result = await _authService.login(username, password);

      session = result;
      status = AuthStatus.authenticated;
      await _storage.saveSession(result.toJson());
    } catch (e) {
      status = AuthStatus.unauthenticated;
      errorMessage = e.toString().replaceFirst('Exception: ', '');
    }
    notifyListeners();
  }

  Future<void> logout() async {
    await _storage.clear();
    session = null;
    status = AuthStatus.unauthenticated;
    notifyListeners();
  }
}