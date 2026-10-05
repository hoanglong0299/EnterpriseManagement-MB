import 'package:flutter/material.dart';

// Nhãn trạng thái nhỏ có màu (Đã duyệt, Chờ duyệt, Từ chối...).
class StatusChip extends StatelessWidget {
  final String label;
  final Color color;

  const StatusChip({super.key, required this.label, required this.color});

  // Màu thường dùng cho các trạng thái duyệt/chấm công.
  static const Color success = Color(0xFF2E7D32);
  static const Color warning = Color(0xFFEF6C00);
  static const Color danger = Color(0xFFC62828);
  static const Color neutral = Color(0xFF616161);
  static const Color info = Color(0xFF1565C0);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(label, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600)),
    );
  }
}
