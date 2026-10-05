import 'package:flutter/material.dart';

class AppTheme {
  // Định nghĩa hằng số màu
  static const Color primaryBlue = Color(0xFF2A5CAA);
  static const Color bgLight = Color(0xFFF5F7FA);

  static ThemeData get lightTheme {
    return ThemeData(
      primaryColor: primaryBlue,
      scaffoldBackgroundColor: bgLight,
      
      // 1. Tự động áp màu xanh cho MỌI AppBar trong app
      appBarTheme: const AppBarTheme(
        backgroundColor: primaryBlue,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: Colors.white),
        titleTextStyle: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
      ),
      
      // 2. Tự động áp màu xanh cho MỌI nút ElevatedButton
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryBlue,
          foregroundColor: Colors.white, 
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        ),
      ),
    );
  }
}