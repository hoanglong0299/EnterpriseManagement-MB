import 'package:flutter/material.dart';

// Giới hạn bề rộng tối đa theo tỉ lệ màn hình để nhãn trạng thái dài tự xuống dòng thay vì tràn ngang.
class CappedWidth extends StatelessWidget {
  final Widget child;
  final double fraction;

  const CappedWidth({super.key, required this.child, this.fraction = 0.45});

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    return ConstrainedBox(constraints: BoxConstraints(maxWidth: width * fraction), child: child);
  }
}
