import 'package:dio/dio.dart';

import '../constants/api_constants.dart';
import '../storage/local_storage.dart';

class ApiClient {
  final Dio dio;
  final LocalStorage storage;

  ApiClient(this.storage)
      : dio = Dio(BaseOptions(
          baseUrl: ApiConstants.baseUrl,
          connectTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 15),
          headers: {'Content-Type': 'application/json'},
        )) {
    dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await storage.readToken();
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },
    ));
  }
}

// Thông báo lỗi để hiện cho người dùng. Backend trả 403 với nội dung rỗng khi tài khoản không có quyền
// (không có "message"), nên phải nhận ra riêng; mất mạng/backend tắt thì không có response nào cả.
String apiErrorMessage(DioException e, String fallback) {
  if (e.response?.statusCode == 403) {
    return 'Bạn không có quyền thực hiện chức năng này.';
  }

  final data = e.response?.data;
  if (data is Map && data['message'] is String) {
    return data['message'] as String;
  }

  if (e.type == DioExceptionType.connectionError ||
      e.type == DioExceptionType.connectionTimeout ||
      e.type == DioExceptionType.receiveTimeout) {
    return 'Không kết nối được máy chủ. Vui lòng kiểm tra mạng.';
  }

  return fallback;
}