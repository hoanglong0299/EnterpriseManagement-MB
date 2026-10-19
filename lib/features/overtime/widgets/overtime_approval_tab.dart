import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/network/api_client.dart';
import '../../../models/overtime.dart';
import '../../../services/live_updates.dart';
import '../../../services/overtime_service.dart';
import '../../../shared/widgets/auto_refresh.dart';
import '../../../shared/widgets/confirm_dialog.dart';
import '../../../shared/widgets/permission_gate.dart';
import '../../../shared/widgets/state_views.dart';
import '../../hr/hr_helpers.dart';
import '../providers/overtime_provider.dart';
import 'overtime_ui.dart';

// Tab "Làm thêm giờ" trong màn Duyệt đơn từ của quản lý: đơn chờ duyệt (duyệt/từ chối) và lịch sử đã xử lý.
class OvertimeApprovalTab extends StatelessWidget {
  const OvertimeApprovalTab({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (ctx) => OvertimeApprovalProvider(OvertimeService(ctx.read<ApiClient>()))..load(),
      child: const _View(),
    );
  }
}

class _View extends StatelessWidget {
  const _View();

  Future<void> _approve(BuildContext context, OvertimeRequest r) async {
    final ok = await confirmDialog(
      context,
      title: 'Duyệt làm thêm giờ',
      message: 'Duyệt đơn của ${r.employeeName}: ${r.dateLabel}, ${r.timeLabel} (${r.durationLabel})?',
      confirmText: 'Duyệt',
    );
    if (!ok || !context.mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    final err = await context.read<OvertimeApprovalProvider>().approve(r.id);
    messenger.showSnackBar(SnackBar(
      content: Text(err ?? 'Đã duyệt đơn làm thêm giờ.'),
      backgroundColor: err == null ? Colors.green : Colors.red,
    ));
  }

  Future<void> _reject(BuildContext context, OvertimeRequest r) async {
    final reason = await askReason(context, title: 'Từ chối đơn của ${r.employeeName}');
    if (reason == null || !context.mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    final err = await context.read<OvertimeApprovalProvider>().reject(r.id, reason);
    messenger.showSnackBar(SnackBar(
      content: Text(err ?? 'Đã từ chối đơn làm thêm giờ.'),
      backgroundColor: err == null ? Colors.green : Colors.red,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final p = context.watch<OvertimeApprovalProvider>();

    Widget body;
    if (p.isLoading && p.pending.isEmpty && p.history.isEmpty) {
      body = const LoadingView();
    } else if (p.error != null && p.pending.isEmpty && p.history.isEmpty) {
      body = ErrorView(message: p.error!, onRetry: p.load);
    } else if (p.pending.isEmpty && p.history.isEmpty) {
      body = RefreshIndicator(
        onRefresh: p.load,
        child: ListView(children: const [
          SizedBox(height: 80),
          EmptyView(message: 'Chưa có đơn làm thêm giờ nào.', icon: Icons.more_time),
        ]),
      );
    } else {
      body = RefreshIndicator(
        onRefresh: p.load,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          children: [
            Text('Chờ duyệt (${p.pending.length})', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            if (p.pending.isEmpty)
              const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Text('Không có đơn chờ duyệt.', style: TextStyle(color: Colors.black54))),
            for (final r in p.pending)
              OvertimeCard(
                request: r,
                showEmployee: true,
                actions: PermissionGate(
                  code: 'overtime.request.approve',
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: p.busyId == r.id ? null : () => _reject(context, r),
                          child: const Text('TỪ CHỐI', style: TextStyle(color: Colors.red)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF5A3FD8)),
                          onPressed: p.busyId == r.id ? null : () => _approve(context, r),
                          child: const Text('DUYỆT'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            if (p.history.isNotEmpty) ...[
              const SizedBox(height: 12),
              const Text('Đã xử lý', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              for (final r in p.history) OvertimeCard(request: r, showEmployee: true),
            ],
          ],
        ),
      );
    }

    return AutoRefresh(
      onRefresh: () => context.read<OvertimeApprovalProvider>().load(silent: true),
      types: NotificationTypes.managerOvertime,
      child: body,
    );
  }
}
