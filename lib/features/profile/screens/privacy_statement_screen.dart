import 'package:flutter/material.dart';

class PrivacyStatementScreen extends StatelessWidget {
  const PrivacyStatementScreen({super.key});

  // Tách biệt dữ liệu văn bản thành một List cố định để code UI không bị rác
  static const List<Map<String, String>> _privacySections = [
    {
      'title': '1. Scope of Data Collection',
      'content': 'To ensure the accuracy of the time-tracking function, the application will collect the following information upon receiving your permission:\n\n'
                 '• Location Data (GPS): Collected only at the exact moment you press the "Check-in/Check-out" button to verify that you are at the designated workplace.\n'
                 '• Biometric Data (Facial/Fingerprint): Images or fingerprint scans are collected to authenticate your identity and prevent proxy attendance (buddy punching).\n'
                 '• Device and System Data: Information regarding your device type (Device ID), operating system, IP address, and access time is collected to record system logs and secure your account.',
    },
    {
      'title': '2. Purpose of Data Use',
      'content': 'All data collected from users is used exclusively for internal business purposes, including:\n\n'
                 '• Verifying the identity, location, and actual working hours of employees.\n'
                 '• Providing an accurate database for the Human Resources Department to calculate salaries, bonuses, and manage shifts.\n'
                 '• Preventing fraudulent activities, location spoofing, or device tampering during the attendance tracking process.',
    },
    {
      'title': '3. Non-Disclosure Commitment',
      'content': 'We strictly commit not to sell, exchange, rent, or provide your personal data, location data, and biometric data to any third party for commercial purposes. Your data is only shared within the following scope:\n\n'
                 '• Managers, System Administrators (Admins), or the Human Resources Department of the company/organization directly managing you.\n'
                 '• Cloud server infrastructure partners who have signed a strict Non-Disclosure Agreement (NDA) with us.',
    },
    {
      'title': '4. Security and Encryption Measures',
      'content': 'The application applies the most advanced digital security standards available. All personal information, especially biometric and location data, is safeguarded using End-to-End Encryption during transmission and storage on our servers. We utilize firewalls and strict security protocols to prevent any unauthorized access, alteration, or destruction of data from external sources.',
    },
    {
      'title': '5. Data Retention Period',
      'content': 'Your attendance data and personal profile will be retained in the system for as long as you maintain your employment status with the company. Upon termination of your employment contract, your biometric data and account will be deactivated, archived, or permanently deleted in accordance with your company\'s personnel records management policies and applicable local laws.',
    },
    {
      'title': '6. User Control Rights',
      'content': 'Users are granted access to review their complete attendance history, including recorded times and locations, directly within the application. In the event you discover inaccurate information or wish to request the correction/deletion of your facial/fingerprint data, you have the right to submit a request directly to the System Administrator or your company\'s Human Resources Department for resolution according to their authority.',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Privacy Statement'),
        backgroundColor: const Color(0xFF2A5CAA),
        elevation: 0,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(20.0),
        itemCount: _privacySections.length,
        itemBuilder: (context, index) {
          final section = _privacySections[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  section['title']!,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2A5CAA),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  section['content']!,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.black87,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}