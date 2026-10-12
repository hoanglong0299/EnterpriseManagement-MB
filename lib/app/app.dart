import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import '../core/network/api_client.dart';
import '../core/storage/local_storage.dart';
import '../features/auth/providers/auth_provider.dart';
import '../features/auth/screens/login_screen.dart';
import '../features/check_in/providers/check_in_provider.dart';
import '../features/dashboard/providers/menu_provider.dart';
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
    final notificationProvider = NotificationProvider(notificationService);
    final messengerKey = GlobalKey<ScaffoldMessengerState>();
    final pushService = PushService(notificationService, notificationProvider, messengerKey);

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
        Provider<PushService>.value(value: pushService),
      ],
      child: MaterialApp(
        scaffoldMessengerKey: messengerKey,
        title: 'EMS',
        debugShowCheckedModeBanner: false,
        // Tiếng Việt cho các thành phần có sẵn của Flutter (hộp chọn ngày, nút OK/Huỷ, tooltip...).
        locale: const Locale('vi', 'VN'),
        supportedLocales: const [Locale('vi', 'VN')],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: const LoginScreen(),
      ),
    );
  }
}