import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../app/theme.dart';
import '../../../services/push_service.dart';
import '../../calendar/screens/calendar_screen.dart';
import '../../home/screens/home_screen.dart';
import '../../leave/providers/leave_provider.dart';
import '../../notifications/providers/notification_provider.dart';
import '../../notifications/screens/notifications_screen.dart';
import '../../profile/providers/profile_provider.dart';
import '../../profile/screens/profile_screen.dart';
import '../../utilities/screens/utilities_screen.dart';
import '../providers/menu_provider.dart';

// Khung màn hình chính sau đăng nhập: 5 tab, Trang chủ (chấm công) ở giữa và là tab mở đầu.
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  static const _tabHome = 2;
  static const _tabNotifications = 3;

  int _currentIndex = _tabHome;
  late final PushService _push;

  // Bấm thông báo hệ thống: chuyển sang tab Thông báo.
  void _openNotificationsTab() {
    _push.pendingOpenTab = false;
    if (mounted) setState(() => _currentIndex = _tabNotifications);
  }

  @override
  void initState() {
    super.initState();
    _push = context.read<PushService>();
    _push.openTabRequests.addListener(_openNotificationsTab);
    if (_push.pendingOpenTab) _currentIndex = _tabNotifications;
    // Đây là màn hình đầu tiên sau khi đăng nhập (hoặc mở lại app khi còn phiên): tải hồ sơ, số dư phép, menu, thông báo.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProfileProvider>().load();
      context.read<LeaveProvider>().load();
      context.read<MenuProvider>().load();
      context.read<NotificationProvider>().startPolling();
      _push.start();
    });
  }

  @override
  void dispose() {
    _push.openTabRequests.removeListener(_openNotificationsTab);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final unread = context.watch<NotificationProvider>().unreadCount;

    final screens = <Widget>[
      const CalendarScreen(),
      const UtilitiesScreen(),
      HomeScreen(onOpenNotifications: () => setState(() => _currentIndex = _tabNotifications)),
      const NotificationsScreen(),
      const ProfileScreen(),
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(child: IndexedStack(index: _currentIndex, children: screens)),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        height: 66,
        elevation: 8,
        shadowColor: Colors.black26,
        onDestinationSelected: (index) => setState(() => _currentIndex = index),
        destinations: [
          const NavigationDestination(
            icon: Icon(Icons.calendar_month_outlined),
            selectedIcon: Icon(Icons.calendar_month),
            label: 'Lịch',
          ),
          const NavigationDestination(
            icon: Icon(Icons.grid_view_outlined),
            selectedIcon: Icon(Icons.grid_view_rounded),
            label: 'Tiện ích',
          ),
          const NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded),
            label: 'Trang chủ',
          ),
          NavigationDestination(
            icon: _bellIcon(Icons.notifications_none, unread),
            selectedIcon: _bellIcon(Icons.notifications, unread),
            label: 'Thông báo',
          ),
          const NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Cá nhân',
          ),
        ],
      ),
    );
  }

  // Icon chuông kèm huy hiệu số chưa đọc (ẩn khi 0, "9+" khi lớn hơn 9).
  Widget _bellIcon(IconData icon, int unread) {
    return Badge(
      isLabelVisible: unread > 0,
      label: Text(unread > 9 ? '9+' : '$unread'),
      child: Icon(icon),
    );
  }
}
