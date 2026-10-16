import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

import '../../services/live_updates.dart';

// Bọc một màn hình để dữ liệu tự cập nhật im lặng: khi có sự kiện đúng loại, theo timer dự phòng
// (chỉ khi màn đang hiển thị và app ở foreground) và khi app quay lại foreground.
// onRefresh phải tải ngầm (không bật vòng tải toàn màn). Không bao giờ chạy chồng hai lần.
class AutoRefresh extends StatefulWidget {
  final Future<void> Function() onRefresh;
  // Rỗng/null = mọi loại.
  final Set<String>? types;
  final Duration fallback;
  // Nguồn sự kiện; mặc định lấy từ Provider (không có thì chỉ chạy timer dự phòng).
  final LiveUpdates? source;
  final Widget child;

  const AutoRefresh({
    super.key,
    required this.onRefresh,
    this.types,
    this.fallback = const Duration(seconds: 45),
    this.source,
    required this.child,
  });

  @override
  State<AutoRefresh> createState() => _AutoRefreshState();
}

class _AutoRefreshState extends State<AutoRefresh> with WidgetsBindingObserver {
  StreamSubscription<dynamic>? _sub;
  Timer? _timer;
  bool _busy = false;
  bool _pending = false;
  bool _foreground = true;
  bool _visible = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _startTimer();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final wasVisible = _visible;
    _visible = TickerMode.valuesOf(context).enabled;
    // Vừa được hiện lại (đổi tab): tải lại để không giữ dữ liệu cũ.
    if (_visible && !wasVisible) _refresh();
    if (_sub == null) {
      final source = widget.source ?? _lookup();
      _sub = source?.events.listen((n) {
        final t = widget.types;
        if (t == null || t.isEmpty || t.contains(n.type)) _refresh();
      });
    }
  }

  LiveUpdates? _lookup() {
    try {
      return Provider.of<LiveUpdates>(context, listen: false);
    } catch (_) {
      return null;
    }
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(widget.fallback, (_) {
      if (_visible && _foreground) _refresh();
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _foreground = true;
      _startTimer();
      _refresh();
    } else if (state == AppLifecycleState.paused) {
      _foreground = false;
      _timer?.cancel();
    }
  }

  Future<void> _refresh() async {
    if (!mounted) return;
    if (_busy) {
      _pending = true;
      return;
    }
    _busy = true;
    try {
      await widget.onRefresh();
    } catch (_) {
      // Làm mới ngầm: lỗi thì bỏ qua.
    }
    _busy = false;
    if (_pending && mounted) {
      _pending = false;
      _refresh();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _sub?.cancel();
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
