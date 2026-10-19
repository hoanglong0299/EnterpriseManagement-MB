import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/network/api_client.dart';
import '../../../models/leave_cancel.dart';
import '../../../services/leave_service.dart';
import '../../../services/live_updates.dart';
import '../../../shared/widgets/auto_refresh.dart';
import '../../../shared/widgets/confirm_dialog.dart';
import '../../../shared/widgets/permission_gate.dart';
import '../../../shared/widgets/state_views.dart';
import '../../../shared/widgets/status_chip.dart';
import '../../attendance/widgets/capped_width.dart';
import '../../hr/hr_helpers.dart';

// Tab "Hủy phép" trong màn Duyệt đơn từ của quản lý: yêu cầu hủy đơn nghỉ đã duyệt nhưng chưa bắt đầu (duyệt thì hoàn phép).
class LeaveCancelTab extends StatelessWidget {
  const LeaveCancelTab({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (ctx) => LeaveCancelProvider(LeaveService(ctx.read<ApiClient>()))..load(),
      child: const _View(),
    );
  }
}

class LeaveCancelProvider extends ChangeNotifier {
  final LeaveService _service;

  LeaveCancelProvider(this._service);

  List<LeaveCancelRequest> pending = [];
  List<LeaveCancelRequest> history = [];
  bool isLoading = false;
  int? busyId;
  String? error;

  Future<void> load({bool silent = false}) async {
    if (!silent) {
      isLoading = true;
      error = null;
      notifyListeners();
    }
    try {
      final results = await Future.wait([_service.getPendingCancels(), _service.getCancelHistory()]);
      pending = results[0];
      history = results[1];
    } catch (e) {
      if (!silent) error = e.toString().replaceFirst('Exception: ', '');
    }
    isLoading = false;
    notifyListeners();
  }

  Future<String?> approve(int id) => _decide(id, () => _service.approveCancel(id));

  Future<String?> reject(int id, String reason) =>
      _decide(id, () => _service.rejectCancel(id, reason.trim().isEmpty ? null : reason.trim()));

  // null = thành công. Thất bại cũng tải lại để bỏ yêu cầu đã được xử lý ở nơi khác.
  Future<String?> _decide(int id, Future<void> Function() action) async {
    busyId = id;
    notifyListeners();
    String? err;
    try {
      await action();
    } catch (e) {
      err = e.toString().replaceFirst('Exception: ', '');
    }
    busyId = null;
    notifyListeners();
    await load(silent: true);
    return err;
  }
}

Color _statusColor(String s) => switch (s) {
      'Approved' => StatusChip.success,
      'Pending' => StatusChip.warning,
      'Rejected' => StatusChip.danger,
      _ => StatusChip.neutral,
    };

class _View extends StatelessWidget {
  const _View();

  Future<void> _approve(BuildContext context, LeaveCancelRequest r) async {
    final ok = await confirmDialog(
      context,
      title: 'Duyệt hủy đơn nghỉ',
      message: 'Hủy đơn ${r.leaveTypeName} của ${r.employeeName} (${r.dateLabel})? Phép đã trừ sẽ được hoàn lại.',
      confirmText: 'Duyệt hủy',
    );
    if (!ok || !context.mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    final err = await context.read<LeaveCancelProvider>().approve(r.id);
    messenger.showSnackBar(SnackBar(content: Text(err ?? 'Đã hủy đơn nghỉ phép.'), backgroundColor: err == null ? Colors.green : Colors.red));
  }

  Future<void> _reject(BuildContext context, LeaveCancelRequest r) async {
    final reason = await askReason(context, title: 'Từ chối hủy đơn của ${r.employeeName}');
    if (reason == null || !context.mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    final err = await context.read<LeaveCancelProvider>().reject(r.id, reason);
    messenger.showSnackBar(SnackBar(content: Text(err ?? 'Đã từ chối yêu cầu hủy.'), backgroundColor: err == null ? Colors.green : Colors.red));
  }

  Widget _card(BuildContext context, LeaveCancelRequest r, {Widget? actions}) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(r.employeeName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF5A3FD8))),
                ),
                CappedWidth(child: StatusChip(label: r.statusLabel, color: _statusColor(r.status))),
              ],
            ),
            const Divider(),
            Text('Loại nghỉ: ${r.leaveTypeName}'),
            Text('Ngày nghỉ: ${r.dateLabel} · ${r.durationLabel}'),
            const SizedBox(height: 4),
            Text('Lý do hủy: ${r.reason}', style: const TextStyle(color: Colors.black54)),
            if (r.status == 'Rejected' && (r.rejectionReason ?? '').isNotEmpty)
              Text('Lý do từ chối: ${r.rejectionReason}', style: const TextStyle(color: Colors.black54)),
            if (actions != null) ...[const SizedBox(height: 12), actions],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = context.watch<LeaveCancelProvider>();

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
          EmptyView(message: 'Chưa có yêu cầu hủy đơn nghỉ nào.', icon: Icons.event_busy),
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
              const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Text('Không có yêu cầu chờ duyệt.', style: TextStyle(color: Colors.black54))),
            for (final r in p.pending)
              _card(
                context,
                r,
                actions: PermissionGate(
                  code: 'leave.request.approve',
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
                          child: const Text('DUYỆT HỦY'),
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
              for (final r in p.history) _card(context, r),
            ],
          ],
        ),
      );
    }

    return AutoRefresh(
      onRefresh: () => context.read<LeaveCancelProvider>().load(silent: true),
      types: const {NotificationTypes.leaveCancelSubmitted, NotificationTypes.leaveCancelApproved, NotificationTypes.leaveCancelRejected},
      child: body,
    );
  }
}
