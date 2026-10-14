import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../app/feature_registry.dart';
import '../../../app/theme.dart';
import '../../dashboard/providers/menu_provider.dart';
import '../../leave/providers/leave_provider.dart';
import '../../leave/screens/leave_status_screen.dart';

// Tiện ích: các chức năng của tài khoản (xin nghỉ, quản lý chấm công, duyệt đơn...) dạng lưới icon.
// Mỗi chức năng chỉ hiện khi menu backend cấp trang tương ứng cho tài khoản (giống bản web, không dựa vào tên role).
class UtilitiesScreen extends StatelessWidget {
  const UtilitiesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final menu = context.watch<MenuProvider>();
    final leaveStatus = context.watch<LeaveProvider>().leaveStatusList;

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
        if (leaveStatus.isNotEmpty) ...[
          _leaveCard(context, leaveStatus),
          const SizedBox(height: 16),
        ],
        if (features.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 40),
            child: Center(
              child: Text('Chưa có chức năng nào được cấp cho tài khoản này.', style: TextStyle(color: Colors.black54)),
            ),
          )
        else
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              childAspectRatio: 0.95,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: features.length,
            itemBuilder: (context, index) => _tile(context, features[index], menu),
          ),
      ],
    );
  }

  Widget _tile(BuildContext context, AppFeature feature, MenuProvider menu) {
    final title = menu.titleOf(feature.route) ?? feature.fallbackTitle;
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: feature.builder)),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.black.withValues(alpha: 0.06)),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: feature.color.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(feature.icon, color: feature.color, size: 24),
              ),
              const SizedBox(height: 8),
              Text(
                title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.ink, height: 1.2),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _leaveCard(BuildContext context, List<Map<String, dynamic>> leaveStatus) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => LeaveStatusScreen(leaveStatusList: leaveStatus)),
        ),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.black.withValues(alpha: 0.06)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Tình trạng nghỉ phép', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.ink)),
                  Icon(Icons.chevron_right, color: AppColors.primary),
                ],
              ),
              const SizedBox(height: 8),
              for (var i = 0; i < leaveStatus.length && i < 3; i++) ...[
                if (i > 0) const Divider(height: 1),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 9),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('${leaveStatus[i]['title']}', style: const TextStyle(fontSize: 13, color: Colors.black87)),
                      Text('${leaveStatus[i]['value']}', style: const TextStyle(fontSize: 13, color: Colors.black54)),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
