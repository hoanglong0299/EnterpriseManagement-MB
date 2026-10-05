import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/network/api_client.dart';
import '../../../models/manager_dashboard.dart';
import '../../../services/manager_service.dart';
import '../../../shared/widgets/state_views.dart';
import '../../../shared/widgets/status_chip.dart';
import '../../auth/providers/auth_provider.dart';
import '../manager_helpers.dart';
import '../providers/manager_dashboard_provider.dart';

// Tổng quan quản lý (tương ứng ManagerDashboardPage bên web): quy mô team, đơn chờ duyệt, có mặt/vắng hôm nay.
class ManagerDashboardScreen extends StatelessWidget {
  const ManagerDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (ctx) => ManagerDashboardProvider(
        ManagerService(ctx.read<ApiClient>()),
        ctx.read<AuthProvider>(),
      )..load(),
      child: const _ManagerDashboardView(),
    );
  }
}

class _ManagerDashboardView extends StatelessWidget {
  const _ManagerDashboardView();

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ManagerDashboardProvider>();
    final data = provider.data;

    Widget body;
    if (provider.isLoading && data == null) {
      body = const LoadingView();
    } else if (data == null) {
      body = ErrorView(message: provider.errorMessage ?? 'Không có dữ liệu.', onRetry: provider.load);
    } else {
      body = RefreshIndicator(
        onRefresh: provider.load,
        child: _buildContent(data),
      );
    }

    return Scaffold(
      backgroundColor: managerBackground,
      appBar: managerAppBar('Tổng quan quản lý'),
      body: body,
    );
  }

  Widget _buildContent(ManagerDashboard d) {
    final cards = [
      _Metric('Quy mô team', d.teamSize, Icons.groups, managerPrimary),
      _Metric('Có mặt hôm nay', d.teamPresentTodayCount, Icons.how_to_reg, StatusChip.success),
      _Metric('Vắng hôm nay', d.teamAbsentTodayCount, Icons.person_off,
          d.teamAbsentTodayCount > 0 ? StatusChip.danger : StatusChip.success),
      _Metric('Đơn nghỉ chờ duyệt', d.pendingLeaveRequestsCount, Icons.flight_takeoff,
          d.pendingLeaveRequestsCount > 0 ? StatusChip.warning : StatusChip.success),
      _Metric('Chỉnh sửa công chờ duyệt', d.pendingAttendanceAdjustmentsCount, Icons.edit_calendar,
          d.pendingAttendanceAdjustmentsCount > 0 ? StatusChip.warning : StatusChip.success),
    ];

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      children: [
        const Text('Tình hình team và các đơn đang chờ duyệt.', style: TextStyle(color: Colors.black54)),
        const SizedBox(height: 12),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.3,
          children: cards.map((m) => _MetricCard(metric: m)).toList(),
        ),
      ],
    );
  }
}

class _Metric {
  final String label;
  final int value;
  final IconData icon;
  final Color color;

  _Metric(this.label, this.value, this.icon, this.color);
}

class _MetricCard extends StatelessWidget {
  final _Metric metric;

  const _MetricCard({required this.metric});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Icon(metric.icon, color: metric.color),
            Text('${metric.value}', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: metric.color)),
            Text(metric.label, style: const TextStyle(color: Colors.black54, fontSize: 13)),
          ],
        ),
      ),
    );
  }
}
