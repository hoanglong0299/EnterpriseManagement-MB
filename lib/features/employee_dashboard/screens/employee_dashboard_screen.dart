import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/network/api_client.dart';
import '../../../services/dashboard_service.dart';
import '../../../shared/widgets/state_views.dart';
import '../../attendance/widgets/today_attendance_card.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/employee_dashboard_provider.dart';

class EmployeeDashboardScreen extends StatelessWidget {
  const EmployeeDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (ctx) => EmployeeDashboardProvider(
        DashboardService(ctx.read<ApiClient>()),
        ctx.read<AuthProvider>(),
      )..load(),
      child: const _EmployeeDashboardView(),
    );
  }
}

class _EmployeeDashboardView extends StatelessWidget {
  const _EmployeeDashboardView();

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<EmployeeDashboardProvider>();
    final data = provider.data;

    Widget body;
    if (provider.isLoading) {
      body = const LoadingView();
    } else if (data == null) {
      body = ErrorView(message: provider.errorMessage ?? 'Không có dữ liệu.', onRetry: provider.load);
    } else {
      body = RefreshIndicator(
        onRefresh: provider.load,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          children: [
            Text('Chào ${data.employeeName}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(
              'Tổng quan chấm công, phép và các yêu cầu đang chờ duyệt.',
              style: TextStyle(color: Colors.grey.shade600),
            ),
            if (provider.errorMessage != null) ...[
              const SizedBox(height: 8),
              Text(provider.errorMessage!, style: const TextStyle(color: Colors.red)),
            ],
            const SizedBox(height: 16),
            TodayAttendanceCard(today: data.todayAttendance, onReturn: provider.load),
            const SizedBox(height: 16),
            _MetricCard(
              icon: Icons.beach_access_outlined,
              label: 'Phép còn lại',
              value: '${_trim(data.totalRemainingLeaveDays)} ngày',
              color: const Color(0xFF2A5CAA),
            ),
            const SizedBox(height: 12),
            _MetricCard(
              icon: Icons.event_note_outlined,
              label: 'Đơn nghỉ chờ duyệt',
              value: '${data.pendingLeaveRequestsCount}',
              color: data.pendingLeaveRequestsCount > 0 ? const Color(0xFFEF6C00) : const Color(0xFF2E7D32),
            ),
            const SizedBox(height: 12),
            _MetricCard(
              icon: Icons.edit_calendar_outlined,
              label: 'Điều chỉnh chấm công chờ duyệt',
              value: '${data.pendingAttendanceAdjustmentsCount}',
              color: data.pendingAttendanceAdjustmentsCount > 0 ? const Color(0xFFEF6C00) : const Color(0xFF2E7D32),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text('Dashboard'),
        backgroundColor: const Color(0xFF2A5CAA),
        foregroundColor: Colors.white,
      ),
      body: body,
    );
  }

  // 21.00 -> "21", 10.5 -> "10.5"
  static String _trim(double v) => v == v.roundToDouble() ? v.toInt().toString() : v.toString();
}

class _MetricCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _MetricCard({required this.icon, required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Row(
        children: [
          CircleAvatar(backgroundColor: color.withValues(alpha: 0.12), child: Icon(icon, color: color)),
          const SizedBox(width: 12),
          Expanded(child: Text(label)),
          Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }
}
