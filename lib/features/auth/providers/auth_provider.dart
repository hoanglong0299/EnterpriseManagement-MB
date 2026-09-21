import 'package:flutter/material.dart';
import '../../../core/storage/local_storage.dart';
import '../../../models/user.dart';
import '../../../services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();

  UserModel? _currentUser;
  bool _isLoading = false;
  String? _errorMessage;

  UserModel? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<bool> login(String username, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final user = await _authService.login(username, password);
      _currentUser = user;

      // Lưu Token vào LocalStorage vừa viết ở Bước 3
      await LocalStorage.saveToken(user.token);

      _isLoading = false;
      notifyListeners();
      return true; // Đăng nhập thành công
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false; // Đăng nhập thất bại
    }
  }
}