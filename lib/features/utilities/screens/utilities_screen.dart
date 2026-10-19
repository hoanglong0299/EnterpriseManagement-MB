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

  // Nhóm theo khu vực của route, cùng thứ tự với thanh bên của web: cá nhân, quản lý, nhân sự, quản trị.
  // Chỉ hiện tiêu đề nhóm khi tài khoản có từ hai nhóm trở lên (nhân viên thường chỉ thấy một lưới như trước).
  static const _groups = [
    ('/employee/', 'Cá nhân'),
    ('/manager/', 'Quản lý'),
    ('/hr/', 'Nhân sự'),
    ('/admin/', 'Quản trị'),
  ];

  List<Widget> _buildGroups(BuildContext context, MenuProvider menu, List<AppFeature> features) {
    final sections = <(String, List<AppFeature>)>[];
    for (final (prefix, label) in _groups) {
      final inGroup = features.where((f) => f.route.startsWith(prefix)).toList();
      if (inGroup.isNotEmpty) sections.add((label, inGroup));
    }
    final grouped = sections.expand((s) => s.$2).toSet();
    final others = features.where((f) => !grouped.contains(f)).toList();
    if (others.isNotEmpty) sections.add(('Khác', others));

    final showTitles = sections.length >= 2;
    return [
      for (final (label, items) in sections) ...[
        if (showTitles)
          Padding(
            padding: const EdgeInsets.only(top: 8, bottom: 10),
            child: Text(
              label.toUpperCase(),
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 0.5, color: Colors.black54),
            ),
          ),
        UtilityGrid(
          items: [
            for (final feature in items)
              UtilityItem(
                title: menu.titleOf(feature.route) ?? feature.fallbackTitle,
                icon: feature.icon,
                color: feature.color,
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: feature.builder)),
              ),
          ],
        ),
        const SizedBox(height: 12),
      ],
    ];
  }

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
          ..._buildGroups(context, menu, features),
      ],
    );
  }
}
