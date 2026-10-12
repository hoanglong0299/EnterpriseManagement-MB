import 'package:dio/dio.dart';

import '../core/network/api_client.dart';
import '../models/app_notification.dart';

class NotificationService {
  final ApiClient _apiClient;

  NotificationService(this._apiClient);

  // Danh sách thông báo mới nhất trước; beforeId để tải trang cũ hơn.
  Future<List<AppNotification>> getList({bool unreadOnly = false, int take = 30, int? beforeId}) async {
    try {
      final response = await _apiClient.dio.get('/notifications', queryParameters: {
        'unreadOnly': unreadOnly,
        'take': take,
        'beforeId': ?beforeId,
      });
      return (response.data as List)
          .map((item) => AppNotification.fromJson(item as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw Exception(apiErrorMessage(e, 'Không thể tải thông báo.'));
    }
  }

  Future<int> getUnreadCount() async {
    try {
      final response = await _apiClient.dio.get('/notifications/unread-count');
      return ((response.data as Map)['count'] as num).toInt();
    } on DioException catch (e) {
      throw Exception(apiErrorMessage(e, 'Không thể tải số thông báo chưa đọc.'));
    }
  }

  Future<void> markRead(int id) async {
    try {
      await _apiClient.dio.put('/notifications/$id/read');
    } on DioException catch (e) {
      throw Exception(apiErrorMessage(e, 'Không thể đánh dấu đã đọc.'));
    }
  }

  Future<void> markAllRead() async {
    try {
      await _apiClient.dio.put('/notifications/read-all');
    } on DioException catch (e) {
      throw Exception(apiErrorMessage(e, 'Không thể đánh dấu đã đọc tất cả.'));
    }
  }

  // Đăng ký token FCM của thiết bị cho tài khoản hiện tại.
  Future<void> registerDeviceToken(String token, String platform) async {
    try {
      await _apiClient.dio.post('/notifications/device-token', data: {'token': token, 'platform': platform});
    } on DioException catch (e) {
      throw Exception(apiErrorMessage(e, 'Không thể đăng ký thiết bị nhận thông báo.'));
    }
  }

  // Gỡ token khi đăng xuất để thiết bị không nhận thông báo của người cũ.
  Future<void> unregisterDeviceToken(String token) async {
    try {
      await _apiClient.dio.delete('/notifications/device-token', queryParameters: {'token': token});
    } on DioException catch (e) {
      throw Exception(apiErrorMessage(e, 'Không thể gỡ thiết bị nhận thông báo.'));
    }
  }
}
