import 'package:flutter/material.dart';
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
      ],
      child: MaterialApp(
        title: 'EMS',
        debugShowCheckedModeBanner: false,
        home: const LoginScreen(),
      ),
    );
  }
}