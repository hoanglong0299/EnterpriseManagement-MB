import '../../../services/live_updates.dart';
import '../../../shared/widgets/auto_refresh.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/network/api_client.dart';
import '../../../core/utils/helpers.dart';
import '../../../models/attendance_adjustment.dart';
import '../../../services/attendance_service.dart';
import '../../../shared/widgets/confirm_dialog.dart';
import '../../../shared/widgets/permission_gate.dart';
import '../../../shared/widgets/state_views.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/employee_attendance_provider.dart';
import '../widgets/adjustment_form.dart';
import '../widgets/attendance_status.dart';
import '../widgets/capped_width.dart';

class EmployeeAttendanceScreen extends StatelessWidget {
  const EmployeeAttendanceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (ctx) => EmployeeAttendanceProvider(
        AttendanceService(ctx.read<ApiClient>()),
        ctx.read<AuthProvider>(),
      )..load(),
      child: const _AttendanceView(),
    );
  }
}

class _AttendanceView extends StatelessWidget {
  const _AttendanceView();

  Future<void> _openAdjustmentForm(BuildContext context) async {
    final provider = context.read<EmployeeAttendanceProvider>();
    final ok = await showAdjustmentForm(context);
    if (ok == true && context.mounted) {
      showMessage(context, 'Đã gửi yêu cầu điều chỉnh chấm công.');
      provider.load();
    }
  }

  Future<void> _export(BuildContext context, EmployeeAttendanceProvider provider) async {
    final error = await provider.exportCsv();
    if (error != null && context.mounted) showMessage(context, error, error: true);
  }

  @override
  Widget build(BuildContext context) {
    return AutoRefresh(
      onRefresh: () => context.read<EmployeeAttendanceProvider>().load(silent: true),
      types: NotificationTypes.employeeAdjustment,
      child: _buildContent(context),
    );
  }

  Widget _buildContent(BuildContext context) {
    final provider = context.watch<EmployeeAttendanceProvider>();

    Widget body;
    if (provider.isLoading) {
      body = const LoadingView();
    } else if (provider.errorMessage != null && provider.adjustments.isEmpty) {
      body = ErrorView(message: provider.errorMessage!, onRetry: provider.load);
    } else {
      body = const _AdjustmentsTab();
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF6F4FC),
      appBar: AppBar(
        title: const Text('Điều chỉnh chấm công'),
        backgroundColor: const Color(0xFF5A3FD8),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            tooltip: 'Xuất CSV lịch sử chấm công',
            onPressed: () => _export(context, provider),
            icon: const Icon(Icons.ios_share),
          ),
        ],
      ),
      body: body,
      floatingActionButton: PermissionGate(
        code: 'attendance.adjustment.self',
        child: FloatingActionButton.extended(
          backgroundColor: const Color(0xFF5A3FD8),
          foregroundColor: Colors.white,
          onPressed: () => _openAdjustmentForm(context),
          icon: const Icon(Icons.edit_calendar_outlined),
          label: const Text('Yêu cầu chỉnh sửa'),
        ),
      ),
    );
  }
}

// ==========================================
// Tab yêu cầu điều chỉnh của tôi
// ==========================================
class _AdjustmentsTab extends StatelessWidget {
  const _AdjustmentsTab();

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<EmployeeAttendanceProvider>();
    final items = provider.adjustments;

    return RefreshIndicator(
      onRefresh: provider.load,
      child: items.isEmpty
          ? ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: const [
                SizedBox(height: 80),
                EmptyView(message: 'Chưa có yêu cầu chỉnh sửa chấm công.'),
              ],
            )
          : ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
              itemCount: items.length,
              itemBuilder: (_, i) => _AdjustmentCard(item: items[i]),
            ),
    );
  }
}

class _AdjustmentCard extends StatelessWidget {
  final AttendanceAdjustment item;
  const _AdjustmentCard({required this.item});

  String _change(String label, DateTime? oldT, DateTime? newT) {
    if (newT == null) return '';
    return '$label: ${formatTime(oldT)} → ${formatTime(newT)}\n';
  }

  @override
  Widget build(BuildContext context) {
    final changes = _change('Giờ vào', item.oldCheckInTime, item.newCheckInTime) +
        _change('Giờ ra', item.oldCheckOutTime, item.newCheckOutTime);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(formatDate(DateTime.parse(item.attendanceDate)), style: const TextStyle(fontWeight: FontWeight.w600)),
              ),
              CappedWidth(child: AdjustmentStatusChip(status: item.status)),
            ],
          ),
          const SizedBox(height: 6),
          if (changes.isNotEmpty) Text(changes.trimRight(), style: const TextStyle(fontSize: 13)),
          const SizedBox(height: 4),
          Text('Lý do: ${item.reason}', style: TextStyle(fontSize: 13, color: Colors.grey.shade700)),
          if (item.status == 'Rejected' && (item.rejectionReason ?? '').isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text('Lý do từ chối: ${item.rejectionReason}', style: const TextStyle(fontSize: 13, color: Colors.red)),
            ),
          if (item.approverName != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                'Quản lý xác nhận: ${item.approverName}${item.approvedAt != null ? ' · ${formatDateTime(item.approvedAt)}' : ''}',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
            ),
          if (item.processedByName != null)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                'HR xử lý: ${item.processedByName}${item.processedAt != null ? ' · ${formatDateTime(item.processedAt)}' : ''}',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
            ),
        ],
      ),
    );
  }
}
