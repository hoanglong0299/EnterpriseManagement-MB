import 'dart:async';

import 'package:flutter/material.dart';

import '../models/app_notification.dart';

// Các loại thông báo backend gửi (dùng làm bộ lọc sự kiện cho từng màn hình).
class NotificationTypes {
  static const adjustmentApplied = 'AdjustmentApplied';
  static const adjustmentManagerApproved = 'AdjustmentManagerApproved';
  static const adjustmentRejected = 'AdjustmentRejected';
  static const adjustmentSubmitted = 'AdjustmentSubmitted';
  static const attendanceNoteCreated = 'AttendanceNoteCreated';
  static const checkInReminder = 'CheckInReminder';
  static const checkOutReminder = 'CheckOutReminder';
  static const leaveApproved = 'LeaveApproved';
  static const leaveRejected = 'LeaveRejected';
  static const leaveSubmitted = 'LeaveSubmitted';
  static const returnApproved = 'ReturnApproved';
  static const returnRejected = 'ReturnRejected';
  static const returnSubmitted = 'ReturnSubmitted';
  static const overtimeSubmitted = 'OvertimeSubmitted';
  static const leaveCancelSubmitted = 'LeaveCancelSubmitted';
  static const leaveCancelApproved = 'LeaveCancelApproved';
  static const leaveCancelRejected = 'LeaveCancelRejected';
  static const overtimeApproved = 'OvertimeApproved';
  static const overtimeRejected = 'OvertimeRejected';
  // Sự kiện cục bộ (không từ backend): dữ liệu chấm công của chính mình vừa đổi (chấm công vào/ra).
  static const localAttendanceChanged = 'LocalAttendanceChanged';

  // Nhân viên: đơn nghỉ / đi làm lại của tôi.
  static const employeeLeave = {leaveApproved, leaveRejected, returnApproved, returnRejected, leaveSubmitted, leaveCancelApproved, leaveCancelRejected};
  // Nhân viên: yêu cầu điều chỉnh chấm công của tôi.
  static const employeeAdjustment = {adjustmentManagerApproved, adjustmentApplied, adjustmentRejected, localAttendanceChanged};
  // Nhân viên: đơn làm thêm giờ của tôi.
  static const employeeOvertime = {overtimeApproved, overtimeRejected, overtimeSubmitted};
  // Quản lý: đơn làm thêm giờ chờ duyệt.
  static const managerOvertime = {overtimeSubmitted, overtimeApproved, overtimeRejected};
  // Quản lý: đơn chờ duyệt và kết quả xử lý.
  static const manager = {
    leaveCancelSubmitted,
    overtimeSubmitted,
    leaveSubmitted,
    returnSubmitted,
    adjustmentSubmitted,
    leaveApproved,
    leaveRejected,
    adjustmentManagerApproved,
    adjustmentRejected,
    adjustmentApplied,
    localAttendanceChanged,
  };
  // HR: hàng chờ xử lý điều chỉnh / đi làm lại / ghi nhận ngoại lệ.
  static const hr = {
    adjustmentManagerApproved,
    returnApproved,
    returnSubmitted,
    adjustmentApplied,
    adjustmentRejected,
    attendanceNoteCreated,
    localAttendanceChanged,
  };
  // Dữ liệu chấm công / số dư phép của tôi (Trang chủ, Lịch, Tiện ích).
  static const myAttendance = {attendanceNoteCreated, adjustmentApplied, leaveApproved, returnApproved, localAttendanceChanged};
  // Mọi loại liên quan (trừ nhắc chấm công).
  static const allRelevant = {
    adjustmentApplied,
    adjustmentManagerApproved,
    adjustmentRejected,
    adjustmentSubmitted,
    attendanceNoteCreated,
    leaveApproved,
    leaveRejected,
    leaveSubmitted,
    returnApproved,
    returnRejected,
    returnSubmitted,
    overtimeApproved,
    overtimeRejected,
    overtimeSubmitted,
    localAttendanceChanged,
  };
}

// Kết quả một lần poll: các thông báo mới nhất + số chưa đọc (nếu lấy được).
class LivePollResult {
  final List<AppNotification> items;
  final int? unreadCount;
  // Các thông báo mới so với lần poll trước (cũ -> mới); lần poll đầu luôn rỗng.
  final List<AppNotification> newItems;

  const LivePollResult(this.items, {this.unreadCount, this.newItems = const []});
}

typedef LiveFetcher = Future<LivePollResult> Function();

// Nguồn sự kiện duy nhất cho tính năng tự cập nhật: poll thông báo mới nhất mỗi 10 giây khi app ở
// foreground, phát từng thông báo mới ra [events] để các màn hình tự tải lại dữ liệu của mình.
class LiveUpdates with WidgetsBindingObserver {
  final LiveFetcher _fetch;
  final GlobalKey<ScaffoldMessengerState>? messengerKey;
  final Duration interval;

  LiveUpdates(this._fetch, {this.messengerKey, this.interval = const Duration(seconds: 10)});

  final StreamController<AppNotification> _events = StreamController<AppNotification>.broadcast();
  final StreamController<LivePollResult> _polls = StreamController<LivePollResult>.broadcast();

  Timer? _timer;
  bool _running = false;
  bool _foreground = true;
  bool _polling = false;
  bool _pollAgain = false;
  int? _lastSeenId;
  // Tăng mỗi lần stop() để bỏ kết quả của request cũ trả về muộn (đổi tài khoản).
  int _epoch = 0;

  Stream<AppNotification> get events => _events.stream;
  Stream<LivePollResult> get polls => _polls.stream;
  bool get isRunning => _running;
  bool get isForeground => _foreground;

  // Bắt đầu poll (sau đăng nhập). Gọi lại khi đang chạy chỉ poll thêm một lần.
  void start() {
    if (!_running) {
      _running = true;
      _foreground = true;
      WidgetsBinding.instance.addObserver(this);
      _startTimer();
    }
    pollNow();
  }

  // Dừng và reset (đăng xuất): lần start sau coi như lần poll đầu.
  void stop() {
    _epoch++;
    _timer?.cancel();
    _timer = null;
    if (_running) WidgetsBinding.instance.removeObserver(this);
    _running = false;
    _polling = false;
    _pollAgain = false;
    _lastSeenId = null;
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(interval, (_) => pollNow());
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!_running) return;
    if (state == AppLifecycleState.resumed) {
      _foreground = true;
      _startTimer();
      pollNow();
    } else if (state == AppLifecycleState.paused) {
      _foreground = false;
      _timer?.cancel();
      _timer = null;
    }
  }

  // Poll ngay (vd. vừa nhận push). Đang poll dở thì chỉ đánh dấu poll lại sau khi xong.
  Future<void> pollNow() async {
    if (!_running || !_foreground) return;
    if (_polling) {
      _pollAgain = true;
      return;
    }
    _polling = true;
    final epoch = _epoch;
    try {
      final result = await _fetch();
      if (epoch != _epoch) return;
      _handle(result);
    } catch (_) {
      // Lỗi mạng thoáng qua: bỏ qua, lần poll sau thử lại.
    } finally {
      if (epoch == _epoch) {
        _polling = false;
        if (_pollAgain) {
          _pollAgain = false;
          pollNow();
        }
      }
    }
  }

  void _handle(LivePollResult result) {
    var maxId = _lastSeenId ?? 0;
    for (final n in result.items) {
      if (n.id > maxId) maxId = n.id;
    }
    final last = _lastSeenId;
    _lastSeenId = maxId;

    final fresh = last == null ? <AppNotification>[] : (result.items.where((n) => n.id > last).toList()..sort((a, b) => a.id.compareTo(b.id)));
    _polls.add(LivePollResult(result.items, unreadCount: result.unreadCount, newItems: fresh));
    for (final n in fresh) {
      _events.add(n);
    }
    _showSnackBar(fresh);
  }

  // Chỉ báo thông báo mới nhất trong đợt, bỏ qua nhắc chấm công.
  void _showSnackBar(List<AppNotification> fresh) {
    final shown = fresh.where((n) => n.type != NotificationTypes.checkInReminder && n.type != NotificationTypes.checkOutReminder);
    if (shown.isEmpty) return;
    final text = shown.last.title;
    if (text.isEmpty) return;
    messengerKey?.currentState
      ?..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(text), behavior: SnackBarBehavior.floating));
  }

  // Phát sự kiện cục bộ để các màn hình liên quan tải lại ngay, không chờ lần poll sau và không báo SnackBar.
  void notifyLocalChange([String type = NotificationTypes.localAttendanceChanged]) {
    if (_events.isClosed) return;
    _events.add(AppNotification(id: 0, type: type, title: '', body: '', isRead: true, createdAt: DateTime.now()));
  }

  void dispose() {
    stop();
    _events.close();
    _polls.close();
  }
}
