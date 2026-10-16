import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../models/app_notification.dart';
import '../../../services/live_updates.dart';
import '../../../services/notification_service.dart';

class NotificationProvider extends ChangeNotifier {
  static const int _pageSize = 30;

  final NotificationService _service;
  final LiveUpdates _live;

  NotificationProvider(this._service, this._live);

  List<AppNotification> items = [];
  int unreadCount = 0;
  bool isLoading = false;
  bool isLoadingMore = false;
  bool hasMore = true;
  bool unreadOnly = false;
  String? errorMessage;

  StreamSubscription<LivePollResult>? _pollSub;
  // Tăng mỗi lần clear() để bỏ kết quả của request cũ trả về muộn (đổi tài khoản).
  int _epoch = 0;

  // Bắt đầu tự làm mới: LiveUpdates poll mỗi 10 giây (và khi quay lại foreground), kết quả dùng chung
  // để cập nhật số chưa đọc và danh sách.
  void startPolling() {
    _pollSub ??= _live.polls.listen(_onPoll);
    _live.start();
  }

  void _onPoll(LivePollResult r) {
    final count = r.unreadCount;
    if (count != null && count != unreadCount) {
      unreadCount = count;
      notifyListeners();
    }
    if (r.newItems.isNotEmpty) load(showSpinner: false);
  }

  Future<void> refreshUnread() async {
    final epoch = _epoch;
    try {
      final count = await _service.getUnreadCount();
      if (epoch != _epoch) return;
      if (count != unreadCount) {
        unreadCount = count;
        notifyListeners();
      }
    } catch (_) {
      // Lỗi mạng thoáng qua: giữ số cũ.
    }
  }

  // Tải lại từ đầu (trang mới nhất).
  Future<void> load({bool showSpinner = true}) async {
    final epoch = _epoch;
    if (showSpinner) {
      isLoading = true;
      notifyListeners();
    }
    errorMessage = null;
    try {
      final list = await _service.getList(unreadOnly: unreadOnly, take: _pageSize);
      if (epoch != _epoch) return;
      items = list;
      hasMore = list.length >= _pageSize;
    } catch (e) {
      if (epoch != _epoch) return;
      errorMessage = e.toString().replaceFirst('Exception: ', '');
    }
    isLoading = false;
    notifyListeners();
    refreshUnread();
  }

  Future<void> setUnreadOnly(bool value) async {
    if (unreadOnly == value) return;
    unreadOnly = value;
    items = [];
    hasMore = true;
    await load();
  }

  // Tải thêm trang cũ hơn khi cuộn xuống cuối.
  Future<void> loadMore() async {
    if (isLoading || isLoadingMore || !hasMore || items.isEmpty) return;
    final epoch = _epoch;
    isLoadingMore = true;
    notifyListeners();
    try {
      final list = await _service.getList(unreadOnly: unreadOnly, take: _pageSize, beforeId: items.last.id);
      if (epoch != _epoch) return;
      items = [...items, ...list];
      hasMore = list.length >= _pageSize;
    } catch (_) {
      // Giữ danh sách hiện tại; người dùng cuộn lại để thử tiếp.
    }
    isLoadingMore = false;
    notifyListeners();
  }

  Future<void> markRead(AppNotification n) async {
    if (n.isRead) return;
    n.isRead = true;
    if (unreadCount > 0) unreadCount--;
    notifyListeners();
    try {
      await _service.markRead(n.id);
    } catch (_) {
      refreshUnread();
    }
  }

  // Trả về thông báo lỗi (null nếu thành công).
  Future<String?> markAllRead() async {
    try {
      await _service.markAllRead();
    } catch (e) {
      return e.toString().replaceFirst('Exception: ', '');
    }
    for (final n in items) {
      n.isRead = true;
    }
    unreadCount = 0;
    notifyListeners();
    if (unreadOnly) await load(showSpinner: false);
    return null;
  }

  // Xoá sạch khi đăng xuất.
  void clear() {
    _epoch++;
    _pollSub?.cancel();
    _pollSub = null;
    _live.stop();
    items = [];
    unreadCount = 0;
    isLoading = false;
    isLoadingMore = false;
    hasMore = true;
    unreadOnly = false;
    errorMessage = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _pollSub?.cancel();
    super.dispose();
  }
}
