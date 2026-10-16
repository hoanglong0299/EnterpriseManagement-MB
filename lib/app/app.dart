import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import '../core/network/api_client.dart';
import 'theme.dart';
import '../core/storage/local_storage.dart';
import '../features/auth/providers/auth_provider.dart';
import '../features/auth/screens/login_screen.dart';
import '../features/check_in/providers/check_in_provider.dart';
import '../features/dashboard/providers/menu_provider.dart';
import '../features/dashboard/screens/dashboard_screen.dart';
import '../features/leave/providers/leave_approval_provider.dart';
import '../features/leave/providers/leave_provider.dart';
import '../features/profile/providers/profile_provider.dart';
import '../services/attendance_service.dart';
import '../services/auth_service.dart';
import '../services/employee_service.dart';
import '../services/leave_service.dart';
import '../services/location_service.dart';
import '../services/menu_service.dart';
import '../services/photo_service.dart';
import '../features/notifications/providers/notification_provider.dart';
import '../services/notification_service.dart';
import '../services/live_updates.dart';
import '../services/push_service.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final storage = LocalStorage();
    final apiClient = ApiClient(storage);
    final authService = AuthService(apiClient);
    final attendanceService = AttendanceService(apiClient);
    final leaveService = LeaveService(apiClient);
    final employeeService = EmployeeService(apiClient);
    final menuService = MenuService(apiClient);
    final notificationService = NotificationService(apiClient);
    final messengerKey = GlobalKey<ScaffoldMessengerState>();
    final liveUpdates = LiveUpdates(
      () async {
        final items = await notificationService.getList(take: 10);
        final unread = await notificationService.getUnreadCount();
        return LivePollResult(items, unreadCount: unread);
      },
      messengerKey: messengerKey,
    );
    final notificationProvider = NotificationProvider(notificationService, liveUpdates);
    final pushService = PushService(notificationService, liveUpdates);

    return MultiProvider(
      providers: [
        // Dùng chung cho các màn hình tự tạo service/provider riêng: context.read<ApiClient>().
        Provider<ApiClient>.value(value: apiClient),
        ChangeNotifierProvider(
          create: (_) => AuthProvider(authService, storage)..restoreSession(),
        ),
        // Dat sau AuthProvider trong danh sach de context.read<AuthProvider>() o day
        // lay duoc dung provider da tao o dong tren (xem giai thich thu tu trong MultiProvider).
        ChangeNotifierProvider(
          create: (context) => CheckInProvider(
            attendanceService,
            LocationService(),
            PhotoService(),
            context.read<AuthProvider>(),
          ),
        ),
        ChangeNotifierProvider(
          create: (context) => LeaveProvider(leaveService, context.read<AuthProvider>()),
        ),
        ChangeNotifierProvider(
          create: (context) => ProfileProvider(employeeService, context.read<AuthProvider>()),
        ),
        ChangeNotifierProvider(create: (_) => MenuProvider(menuService)),
        ChangeNotifierProvider(create: (_) => LeaveApprovalProvider(leaveService)),
        ChangeNotifierProvider.value(value: notificationProvider),
        Provider<LiveUpdates>.value(value: liveUpdates),
        Provider<PushService>.value(value: pushService),
      ],
      child: MaterialApp(
        scaffoldMessengerKey: messengerKey,
        title: 'EMS',
        theme: buildAppTheme(),
        debugShowCheckedModeBanner: false,
        // Tiếng Việt cho các thành phần có sẵn của Flutter (hộp chọn ngày, nút OK/Huỷ, tooltip...).
        locale: const Locale('vi', 'VN'),
        supportedLocales: const [Locale('vi', 'VN')],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: const _AuthGate(),
      ),
    );
  }
}

// Màn hình khởi đầu: còn phiên đăng nhập hợp lệ thì vào thẳng Dashboard, không bắt đăng nhập lại.
class _AuthGate extends StatelessWidget {
  const _AuthGate();

  @override
  Widget build(BuildContext context) {
    final status = context.watch<AuthProvider>().status;
    switch (status) {
      case AuthStatus.unknown:
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      case AuthStatus.authenticated:
        return const DashboardScreen();
      case AuthStatus.loading:
      case AuthStatus.unauthenticated:
        return const LoginScreen();
    }
  }
}