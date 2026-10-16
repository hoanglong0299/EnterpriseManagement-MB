import 'package:flutter/material.dart';

// Gắn chấm đỏ báo số lượng lên góc một icon. Khác `Badge` của Flutter: bố cục KHÔNG đổi khi số lượng đổi,
// icon luôn nằm đúng một chỗ (căn giữa), chấm đỏ chỉ là lớp nổi lên trên, nên icon không bị xê dịch.
class CountBadge extends StatelessWidget {
  final int count;
  final Widget child;
  final int maxShown;

  const CountBadge({super.key, required this.count, required this.child, this.maxShown = 9});

  @override
  Widget build(BuildContext context) {
    final label = count > maxShown ? '$maxShown+' : '$count';

    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.center,
      children: [
        child,
        if (count > 0)
          Positioned(
            top: -6,
            right: -8,
            // Cỡ chữ của hệ thống không làm to chấm đỏ: chấm luôn gọn ở góc icon.
            child: MediaQuery.withNoTextScaling(
              child: Container(
                constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                padding: const EdgeInsets.symmetric(horizontal: 4),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: const Color(0xFFE53935),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.white, width: 1.2),
                ),
                child: Text(
                  label,
                  maxLines: 1,
                  style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700, height: 1.1),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
