import 'package:flutter/material.dart';

// Màn hình tạm cho chức năng chưa làm xong; mỗi chức năng sẽ được thay bằng màn hình thật.
class FeaturePlaceholder extends StatelessWidget {
  final String title;

  const FeaturePlaceholder(this.title, {super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title), backgroundColor: const Color(0xFF2A5CAA), foregroundColor: Colors.white),
      body: const Center(child: Text('Chức năng đang được xây dựng')),
    );
  }
}
