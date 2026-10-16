import '../../../services/live_updates.dart';
import '../../../shared/widgets/auto_refresh.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../app/feature_registry.dart';
import '../../../app/theme.dart';
import '../../dashboard/providers/menu_provider.dart';
import '../../leave/providers/leave_provider.dart';
import '../../leave/screens/leave_status_screen.dart';
import '../widgets/utility_grid.dart';

// Tiện ích: các chức năng của tài khoản (xin nghỉ, quản lý chấm công, duyệt đơn...) dạng lưới icon.
// Mỗi chức năng chỉ hiện khi menu backend cấp trang tương ứng cho tài khoản (giống bản web, không dựa vào tên role).
class UtilitiesScreen extends StatelessWidget {
  const UtilitiesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AutoRefresh(
      onRefresh: () => context.read<LeaveProvider>().load(silent: true),
      types: NotificationTypes.myAttendance,
      child: _buildContent(context),
    );
  }

  Widget _buildContent(BuildContext context) {
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
                  Expanded(
                    child: Text('Tình trạng nghỉ phép', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.ink)),
                  ),
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
                      Expanded(
                        child: Text('${leaveStatus[i]['title']}', style: const TextStyle(fontSize: 13, color: Colors.black87)),
                      ),
                      const SizedBox(width: 8),
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
