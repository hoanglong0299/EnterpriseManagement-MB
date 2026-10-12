import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../features/notifications/providers/notification_provider.dart';
import 'notification_service.dart';

// Nhận thông báo khi app ở nền/đã đóng: Android tự hiển thị notification message, nên chỉ cần hàm rỗng.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {}

// Thông báo đẩy FCM phía client. Chỉ chạy trên Android/iOS; thiếu cấu hình Firebase thì bỏ qua,
// hộp thông báo trong app vẫn dùng bình thường.
class PushService {
  final NotificationService _service;
  final NotificationProvider _notifications;
  final GlobalKey<ScaffoldMessengerState> messengerKey;

  PushService(this._service, this._notifications, this.messengerKey);

  // Dashboard lắng nghe để chuyển sang tab Thông báo (khi bấm thông báo hệ thống).
  final ValueNotifier<int> openTabRequests = ValueNotifier<int>(0);
  // Bấm thông báo lúc app đóng: Dashboard chưa dựng xong, giữ cờ để đọc khi initState.
  bool pendingOpenTab = false;

  bool _firebaseReady = false;
  bool _initTried = false;
  bool _listening = false;
  String? _token;
  StreamSubscription<String>? _refreshSub;
  StreamSubscription<RemoteMessage>? _foregroundSub;
  StreamSubscription<RemoteMessage>? _openedSub;

  bool get _supported =>
      !kIsWeb && (defaultTargetPlatform == TargetPlatform.android || defaultTargetPlatform == TargetPlatform.iOS);

  String get _platform => defaultTargetPlatform == TargetPlatform.iOS ? 'ios' : 'android';

  Future<bool> _ensureFirebase() async {
    if (_initTried) return _firebaseReady;
    _initTried = true;
    try {
      await Firebase.initializeApp();
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
      _firebaseReady = true;
    } catch (e) {
      debugPrint('Push: bỏ qua thông báo đẩy vì chưa cấu hình Firebase ($e)');
    }
    return _firebaseReady;
  }

  // Gọi sau khi đăng nhập thành công.
  Future<void> start() async {
    if (!_supported) return;
    try {
      if (!await _ensureFirebase()) return;
      final messaging = FirebaseMessaging.instance;
      await messaging.requestPermission();
      final token = await messaging.getToken();
      if (token != null) {
        _token = token;
        await _register(token);
      }
      if (_listening) return;
      _listening = true;
      _refreshSub = messaging.onTokenRefresh.listen((t) {
        _token = t;
        _register(t);
      });
      _foregroundSub = FirebaseMessaging.onMessage.listen(_onForeground);
      _openedSub = FirebaseMessaging.onMessageOpenedApp.listen((_) => _requestOpenTab());
      final initial = await messaging.getInitialMessage();
      if (initial != null) _requestOpenTab();
    } catch (e) {
      debugPrint('Push: lỗi khởi động ($e)');
    }
  }

  // Gọi khi đăng xuất: gỡ token khỏi tài khoản cũ.
  Future<void> stop() async {
    await _refreshSub?.cancel();
    await _foregroundSub?.cancel();
    await _openedSub?.cancel();
    _refreshSub = _foregroundSub = _openedSub = null;
    _listening = false;
    pendingOpenTab = false;
    final token = _token;
    _token = null;
    if (token == null) return;
    try {
      await _service.unregisterDeviceToken(token);
    } catch (_) {}
  }

  Future<void> _register(String token) async {
    try {
      await _service.registerDeviceToken(token, _platform);
    } catch (e) {
      debugPrint('Push: không đăng ký được token ($e)');
    }
  }

  void _onForeground(RemoteMessage message) {
    _notifications.refreshUnread();
    _notifications.load(showSpinner: false);
    final n = message.notification;
    if (n == null) return;
    final text = [if (n.title != null) n.title!, if (n.body != null) n.body!].join('\n');
    messengerKey.currentState
      ?..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(text), behavior: SnackBarBehavior.floating));
  }

  void _requestOpenTab() {
    pendingOpenTab = true;
    openTabRequests.value++;
  }
}
