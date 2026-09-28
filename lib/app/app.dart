import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/network/api_client.dart';
import '../core/storage/local_storage.dart';
import '../features/auth/providers/auth_provider.dart';
import '../features/auth/screens/login_screen.dart';
import '../features/check_in/providers/check_in_provider.dart';
import '../services/attendance_service.dart';
import '../services/auth_service.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final storage = LocalStorage();
    final apiClient = ApiClient(storage);
    final authService = AuthService(apiClient);
    final attendanceService = AttendanceService(apiClient);

    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => AuthProvider(authService, storage)..restoreSession(),
        ),
        // Dat sau AuthProvider trong danh sach de context.read<AuthProvider>() o day
        // lay duoc dung provider da tao o dong tren (xem giai thich thu tu trong MultiProvider).
        ChangeNotifierProvider(
          create: (context) => CheckInProvider(attendanceService, context.read<AuthProvider>()),
        ),
      ],
      child: MaterialApp(
        title: 'EMS',
        debugShowCheckedModeBanner: false,
        home: const LoginScreen(),
      ),
    );
  }
}