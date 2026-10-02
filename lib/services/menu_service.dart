import 'package:dio/dio.dart';

import '../core/network/api_client.dart';
import '../models/app_menu.dart';

class MenuService {
  final ApiClient _apiClient;

  MenuService(this._apiClient);

  // Danh sach menu ma Admin da cap quyen cho tai khoan dang dang nhap (giong cach ban web dung de gac trang).
  Future<List<AppMenu>> getMine() async {
    try {
      final response = await _apiClient.dio.get('/menus/mine');
      return (response.data as List)
          .map((item) => AppMenu.fromJson(item as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw Exception(apiErrorMessage(e, 'Không thể tải menu.'));
    }
  }
}
