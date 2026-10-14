import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../app/theme.dart';
import '../../../core/utils/vi_date.dart';
import '../../check_in/providers/check_in_provider.dart';
import '../../notifications/providers/notification_provider.dart';
import '../../profile/providers/profile_provider.dart';
import '../widgets/check_button.dart';
import '../widgets/home_header.dart';
import '../widgets/work_summary_card.dart';

// Trang chủ: lời chào, thẻ giờ làm hôm nay và nút chấm công vào/ra.
class HomeScreen extends StatefulWidget {
  // Bấm chuông trên header thì mở tab Thông báo của màn hình chính.
  final VoidCallback onOpenNotifications;

  const HomeScreen({super.key, required this.onOpenNotifications});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CheckInProvider>().loadToday();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // Mở lại app (vd sau khi bấm thông báo) thì tải lại trạng thái chấm công hôm nay.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) context.read<CheckInProvider>().loadToday();
  }

  Future<void> _handleCheck() async {
    final provider = context.read<CheckInProvider>();
    final wasClockedIn = provider.hasClockedIn;
    await provider.performAction(wasClockedIn ? 'CLOCK OUT' : 'CLOCK IN');
    if (!mounted) return;

    final error = provider.errorMessage;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(error ?? (wasClockedIn ? 'Chấm công ra thành công!' : 'Chấm công vào thành công!')),
        backgroundColor: error == null ? Colors.green : Colors.red,
        duration: Duration(seconds: error == null ? 2 : 8),
        // Lỗi do chưa cấp quyền / GPS tắt thì cho nút mở thẳng màn hình Cài đặt.
        action: provider.settingsTarget == null
            ? null
            : SnackBarAction(label: 'CÀI ĐẶT', textColor: Colors.white, onPressed: provider.openSettings),
      ),
    );
  }

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 11) return 'Chào buổi sáng';
    if (hour < 13) return 'Chào buổi trưa';
    if (hour < 18) return 'Chào buổi chiều';
    return 'Chào buổi tối';
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CheckInProvider>();
    final name = context.watch<ProfileProvider>().displayName;
    final unread = context.watch<NotificationProvider>().unreadCount;
    final office = provider.office;

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: provider.loadToday,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          HomeHeader(
            greeting: '${_greeting()}, ${_shortName(name)}',
            subtitle: 'Chúc bạn một ngày hiệu quả',
            name: name,
            unread: unread,
            onBellTap: widget.onOpenNotifications,
          ),
          const SizedBox(height: 16),
          WorkSummaryCard(record: provider.today),
          const SizedBox(height: 12),
          Center(
            child: CheckButton(
              checkedIn: provider.hasClockedIn,
              loading: provider.isLoading,
              onPressed: _handleCheck,
            ),
          ),
          const SizedBox(height: 8),
          if (office != null)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.location_on_outlined, size: 16, color: Colors.grey),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    '${office.name} · bán kính ${office.allowedRadiusMeters.round()} m',
                    style: const TextStyle(color: Colors.grey, fontSize: 12.5),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          const SizedBox(height: 6),
          Center(
            child: Text(
              '${viWeekdayFull(DateTime.now().weekday)}, ${DateFormat('dd/MM/yyyy').format(DateTime.now())}',
              style: const TextStyle(color: Colors.grey, fontSize: 12.5),
            ),
          ),
        ],
      ),
    );
  }

  // Tên người Việt: lấy từ cuối (tên gọi) cho lời chào ngắn gọn.
  String _shortName(String full) {
    final parts = full.trim().split(RegExp(r'\s+'));
    return parts.isEmpty || parts.first.isEmpty ? '' : parts.last;
  }
}
