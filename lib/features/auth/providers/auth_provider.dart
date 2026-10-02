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

  Future<void> restoreSession() async {
    final saved = await _storage.readSession();
    if (saved == null) {
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

      // Ứng dụng này là của nhân viên (chấm công, nghỉ phép, hồ sơ cá nhân) nên cần hồ sơ nhân viên.
      // Tài khoản không có (vd Admin) thì dừng ở đây, không lưu phiên. Kiểm tra theo hồ sơ chứ không theo tên role.
      if (result.employeeCode == null) {
        throw Exception(
          'Tài khoản này không có hồ sơ nhân viên nên không dùng được ứng dụng di động. Vui lòng dùng bản web.',
        );
      }

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