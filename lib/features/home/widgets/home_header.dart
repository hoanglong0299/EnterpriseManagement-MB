import 'package:flutter/material.dart';

import '../../../app/theme.dart';

// Đầu Trang chủ: avatar + lời chào bên trái, chuông thông báo (kèm số chưa đọc) bên phải.
class HomeHeader extends StatelessWidget {
  final String greeting;
  final String subtitle;
  final String name;
  final int unread;
  final VoidCallback onBellTap;

  const HomeHeader({
    super.key,
    required this.greeting,
    required this.subtitle,
    required this.name,
    required this.unread,
    required this.onBellTap,
  });

  @override
  Widget build(BuildContext context) {
    final initial = name.trim().isEmpty ? '?' : name.trim().characters.first.toUpperCase();

    return Row(
      children: [
        Container(
          width: 46,
          height: 46,
          decoration: const BoxDecoration(shape: BoxShape.circle, gradient: AppColors.buttonGradient),
          alignment: Alignment.center,
          child: Text(initial, style: const TextStyle(color: Colors.white, fontSize: 19, fontWeight: FontWeight.bold)),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                greeting,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: AppColors.ink),
              ),
              const SizedBox(height: 2),
              Text(subtitle, style: const TextStyle(fontSize: 12.5, color: Colors.black54)),
            ],
          ),
        ),
        InkWell(
          onTap: onBellTap,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(color: AppColors.tint, borderRadius: BorderRadius.circular(14)),
            child: Badge(
              isLabelVisible: unread > 0,
              label: Text(unread > 9 ? '9+' : '$unread'),
              child: const Icon(Icons.notifications_none_rounded, color: AppColors.primary),
            ),
          ),
        ),
      ],
    );
  }
}
