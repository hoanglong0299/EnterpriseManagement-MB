import '../../../services/live_updates.dart';
import '../../../shared/widgets/auto_refresh.dart';
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
    return AutoRefresh(
      onRefresh: () => context.read<ManagerDashboardProvider>().load(silent: true),
      types: NotificationTypes.manager,
      child: _buildBody(context),
    );
  }

  Widget _buildBody(BuildContext context) {
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
      ManagerMetric('Quy mô team', d.teamSize, Icons.groups, managerPrimary),
      ManagerMetric('Có mặt hôm nay', d.teamPresentTodayCount, Icons.how_to_reg, StatusChip.success),
      ManagerMetric('Vắng hôm nay', d.teamAbsentTodayCount, Icons.person_off,
          d.teamAbsentTodayCount > 0 ? StatusChip.danger : StatusChip.success),
      if (d.teamOnLeaveTodayCount != null)
        ManagerMetric('Nghỉ phép hôm nay', d.teamOnLeaveTodayCount!, Icons.beach_access, StatusChip.info),
      ManagerMetric('Đơn nghỉ chờ duyệt', d.pendingLeaveRequestsCount, Icons.flight_takeoff,
          d.pendingLeaveRequestsCount > 0 ? StatusChip.warning : StatusChip.success),
      ManagerMetric('Chỉnh sửa công chờ duyệt', d.pendingAttendanceAdjustmentsCount, Icons.edit_calendar,
          d.pendingAttendanceAdjustmentsCount > 0 ? StatusChip.warning : StatusChip.success),
    ];

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      children: [
        const Text('Tình hình team và các đơn đang chờ duyệt.', style: TextStyle(color: Colors.black54)),
        const SizedBox(height: 12),
        ManagerMetricGrid(metrics: cards),
      ],
    );
  }
}

class ManagerMetric {
  final String label;
  final int value;
  final IconData icon;
  final Color color;

  ManagerMetric(this.label, this.value, this.icon, this.color);
}

// Lưới 2 cột: mỗi hàng cao theo ô nhiều chữ nhất nên nhãn dài/chữ lớn không bị tràn.
class ManagerMetricGrid extends StatelessWidget {
  final List<ManagerMetric> metrics;

  const ManagerMetricGrid({super.key, required this.metrics});

  static const double _spacing = 12;

  @override
  Widget build(BuildContext context) {
    final rows = <Widget>[];
    for (var start = 0; start < metrics.length; start += 2) {
      final chunk = metrics.skip(start).take(2).toList();
      rows.add(
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(child: _MetricCard(metric: chunk[0])),
              const SizedBox(width: _spacing),
              Expanded(child: chunk.length > 1 ? _MetricCard(metric: chunk[1]) : const SizedBox.shrink()),
            ],
          ),
        ),
      );
      if (start + 2 < metrics.length) rows.add(const SizedBox(height: _spacing));
    }
    return Column(children: rows);
  }
}

class _MetricCard extends StatelessWidget {
  final ManagerMetric metric;

  const _MetricCard({required this.metric});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
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
            const SizedBox(height: 8),
            Text('${metric.value}', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: metric.color)),
            Text(metric.label, style: const TextStyle(color: Colors.black54, fontSize: 13)),
          ],
        ),
      ),
    );
  }
}
