import 'package:enterprise_management/features/auth/screens/login_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'features/auth/providers/auth_provider.dart';
// 1. Thêm import Provider và Screen của Check In
import 'features/check_in/providers/check_in_provider.dart'; 
import 'features/check_in/screens/check_in_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        // Khai báo CheckInProvider ở đây
        ChangeNotifierProvider(create: (_) => CheckInProvider()), 
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'App Chấm Công',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: false,
      ),
      // 2. Thay LoginScreen() thành CheckInScreen()
      home: const LoginScreen(), 
    );
  }
}