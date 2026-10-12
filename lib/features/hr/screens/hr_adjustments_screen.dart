import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/network/api_client.dart';
import '../../../core/utils/helpers.dart';
import '../../../models/attendance_adjustment.dart';
import '../../../services/hr_service.dart';
import '../../../shared/widgets/confirm_dialog.dart';
import '../../../shared/widgets/permission_gate.dart';
import '../../../shared/widgets/state_views.dart';
import '../hr_helpers.dart';
import '../providers/hr_adjustments_provider.dart';

// Xử lý điều chỉnh công (route /hr/adjustments): các yêu cầu Manager đã duyệt, chờ HR áp dụng.
class HrAdjustmentsScreen extends StatelessWidget {
  const HrAdjustmentsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (ctx) => HrAdjustmentsProvider(HrService(ctx.read<ApiClient>()))..load(),
      child: const _View(),
    );
  }
}

class _View extends StatelessWidget {
  const _View();

  Future<void> _apply(BuildContext context, AttendanceAdjustment a) async {
    final ok = await confirmDialog(
      context,
      title: 'Áp dụng điều chỉnh',
      message: 'Áp dụng đúng giờ đề xuất cho ${a.employeeName} ngày ${formatDate(parseDay(a.attendanceDate))}?',
      confirmText: 'Áp dụng',
    );
    if (!ok || !context.mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    final err = await context.read<HrAdjustmentsProvider>().apply(a.id);
    messenger.showSnackBar(SnackBar(content: Text(err ?? 'Đã áp dụng điều chỉnh.'), backgroundColor: err == null ? Colors.green : Colors.red));
  }

  Future<void> _reject(BuildContext context, AttendanceAdjustment a) async {
    final reason = await askReason(context, title: 'Từ chối yêu cầu của ${a.employeeName}');
    if (reason == null || !context.mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    final err = await context.read<HrAdjustmentsProvider>().reject(a.id, reason);
    messenger.showSnackBar(SnackBar(content: Text(err ?? 'Đã từ chối yêu cầu.'), backgroundColor: err == null ? Colors.green : Colors.red));
  }

  @override
  Widget build(BuildContext context) {
    final p = context.watch<HrAdjustmentsProvider>();

    Widget body;
    if (p.isLoading && p.items.isEmpty) {
      body = const LoadingView();
    } else if (p.error != null && p.items.isEmpty) {
      body = ErrorView(message: p.error!, onRetry: p.load);
    } else if (p.items.isEmpty) {
      body = RefreshIndicator(
        onRefresh: p.load,
        child: ListView(children: const [
          SizedBox(height: 80),
          EmptyView(message: 'Không có yêu cầu nào chờ xử lý.', icon: Icons.task_alt),
        ]),
      );
    } else {
      body = RefreshIndicator(
        onRefresh: p.load,
        child: ListView.separated(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(12),
          itemCount: p.items.length,
          separatorBuilder: (_, _) => const SizedBox(height: 8),
          itemBuilder: (ctx, i) {
            final a = p.items[i];
            final busy = p.busyId == a.id;
            return Card(
              elevation: 0,
              margin: EdgeInsets.zero,
              color: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(child: Text('${a.employeeName} (${a.employeeCode})', style: const TextStyle(fontWeight: FontWeight.w600))),
                        Text(formatDate(parseDay(a.attendanceDate)), style: const TextStyle(color: Colors.black54)),
                      ],
                    ),
                    const SizedBox(height: 6),
                    _TimeLine(label: 'Giờ vào', oldTime: a.oldCheckInTime, newTime: a.newCheckInTime),
                    _TimeLine(label: 'Giờ ra', oldTime: a.oldCheckOutTime, newTime: a.newCheckOutTime),
                    const SizedBox(height: 6),
                    Text('Lý do: ${a.reason}'),
                    if (a.approverName != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text('Quản lý duyệt: ${a.approverName}${a.approvedAt == null ? '' : ' · ${formatDateTime(a.approvedAt)}'}',
                            style: const TextStyle(color: Colors.black54, fontSize: 12)),
                      ),
                    PermissionGate(
                      code: 'attendance.adjustment.apply',
                      child: Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            OutlinedButton(onPressed: busy ? null : () => _reject(ctx, a), child: const Text('Từ chối')),
                            const SizedBox(width: 8),
                            FilledButton(
                              onPressed: busy ? null : () => _apply(ctx, a),
                              style: FilledButton.styleFrom(backgroundColor: hrPrimary),
                              child: busy ? busyIndicator() : const Text('Áp dụng'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      );
    }

    return Scaffold(backgroundColor: hrBackground, appBar: hrAppBar('Xử lý điều chỉnh công'), body: body);
  }
}

// Dòng "Giờ vào: 08:10 -> 08:00"; bỏ qua khi yêu cầu không đề xuất đổi giờ đó.
class _TimeLine extends StatelessWidget {
  final String label;
  final DateTime? oldTime;
  final DateTime? newTime;

  const _TimeLine({required this.label, required this.oldTime, required this.newTime});

  @override
  Widget build(BuildContext context) {
    if (newTime == null) return const SizedBox.shrink();
    return Text('$label: ${formatTime(oldTime)} → ${formatTime(newTime)}', style: const TextStyle(fontSize: 14));
  }
}
