import 'package:dio/dio.dart';
import '../constants/api_constants.dart';
import '../storage/local_storage.dart';

class ApiClient {
  late final Dio _dio;

  ApiClient() {
    _dio = Dio(
      BaseOptions(
        baseUrl: ApiConstants.baseUrl,
        connectTimeout: const Duration(seconds: 10), // Hết hạn kết nối sau 10s
        receiveTimeout: const Duration(seconds: 10), // Hết hạn nhận dữ liệu sau 10s
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    // Cấu hình Interceptor xử lý dữ liệu trước khi gửi và nhận
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          // Tự động lấy Token từ LocalStorage và gắn vào Header
          final token = await LocalStorage.getToken();
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options);
        },
        onError: (DioException error, handler) {
          // Xử lý lỗi chung (như hết hạn Token - 401)
          if (error.response?.statusCode == 401) {
            // Có thể thêm logic tự động đăng xuất tại đây
          }
          return handler.next(error);
        },
      ),
    );
  }

  // Expose instance của Dio ra ngoài để các Service sử dụng
  Dio get client => _dio;
}