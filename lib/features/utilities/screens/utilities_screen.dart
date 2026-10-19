import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../app/feature_registry.dart';
import '../../../app/theme.dart';
import '../../dashboard/providers/menu_provider.dart';
import '../widgets/utility_grid.dart';

// Tiện ích: các chức năng của tài khoản (xin nghỉ, quản lý chấm công, duyệt đơn...) dạng lưới icon.
// Mỗi chức năng chỉ hiện khi menu backend cấp trang tương ứng cho tài khoản (giống bản web, không dựa vào tên role).
class UtilitiesScreen extends StatelessWidget {
  const UtilitiesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final menu = context.watch<MenuProvider>();

    final features = [
      for (final feature in appFeatures)
        if (menu.hasRoute(feature.route)) feature,
    ];

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      children: [
        const Text('Tiện ích', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.ink)),
        const SizedBox(height: 4),
        const Text('Các chức năng dành cho tài khoản của bạn', style: TextStyle(fontSize: 13, color: Colors.black54)),
        const SizedBox(height: 16),
        if (features.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 40),
            child: Center(
              child: Text('Chưa có chức năng nào được cấp cho tài khoản này.', style: TextStyle(color: Colors.black54)),
            ),
          )
        else
          UtilityGrid(
            items: [
              for (final feature in features)
                UtilityItem(
                  title: menu.titleOf(feature.route) ?? feature.fallbackTitle,
                  icon: feature.icon,
                  color: feature.color,
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: feature.builder)),
                ),
            ],
          ),
      ],
    );
  }
}
