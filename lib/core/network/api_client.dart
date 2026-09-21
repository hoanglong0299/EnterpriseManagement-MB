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