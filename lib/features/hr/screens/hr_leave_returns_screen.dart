import '../../../services/live_updates.dart';
import '../../../shared/widgets/auto_refresh.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/network/api_client.dart';
import '../../../core/utils/helpers.dart';
import '../../../models/attendance_hr.dart';
import '../../../services/hr_service.dart';
import '../../../shared/widgets/confirm_dialog.dart';
import '../../../shared/widgets/permission_gate.dart';
import '../../../shared/widgets/state_views.dart';
import '../../../shared/widgets/status_chip.dart';
import '../hr_helpers.dart';
import '../providers/hr_returns_provider.dart';

// Xác nhận rút ngắn phép (route /hr/leave-returns, quyền attendance.note.manage).
class HrLeaveReturnsScreen extends StatelessWidget {
  const HrLeaveReturnsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (ctx) => HrReturnsProvider(HrService(ctx.read<ApiClient>()))..load(),
      child: const _View(),
    );
  }
}

class _View extends StatelessWidget {
  const _View();

  void _openDetail(BuildContext context, LeaveReturnRequest r) {
    final provider = context.read<HrReturnsProvider>();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => ChangeNotifierProvider.value(
        value: provider,
        child: _DetailSheet(request: r),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AutoRefresh(
      onRefresh: () => context.read<HrReturnsProvider>().load(silent: true),
      types: NotificationTypes.hr,
      child: _buildContent(context),
    );
  }

  Widget _buildContent(BuildContext context) {
    final p = context.watch<HrReturnsProvider>();

    Widget body;
    if (p.isLoading && p.items.isEmpty) {
      body = const LoadingView();
    } else if (p.error != null && p.items.isEmpty) {
      body = ErrorView(message: p.error!, onRetry: p.load);
    } else if (p.items.isEmpty) {
      body = RefreshIndicator(
        onRefresh: p.load,
        child: ListView(
          children: const [
            SizedBox(height: 80),
            EmptyView(message: 'Không có yêu cầu rút ngắn nghỉ phép nào chờ xác nhận.', icon: Icons.task_alt),
          ],
        ),
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
            final r = p.items[i];
            final awaiting = r.sessions.where((s) => s.state == 'AwaitingHr').length;
            return Card(
              elevation: 0,
              margin: EdgeInsets.zero,
              color: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () => _openDetail(ctx, r),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              '${r.employeeName} (${r.employeeCode})',
                              style: const TextStyle(fontWeight: FontWeight.w600),
                            ),
                          ),
                          StatusChip(label: 'Chờ xác nhận', color: hrAmber),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Đi làm lại từ ${sessionName(r.fromSession).toLowerCase()} ${formatDate(r.fromDate)}',
                        style: const TextStyle(color: Colors.black54, fontSize: 13),
                      ),
                      Text('$awaiting buổi chờ xác nhận', style: const TextStyle(color: Colors.black54, fontSize: 13)),
                      const SizedBox(height: 4),
                      Text(r.reason, maxLines: 2, overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      );
    }

    return Scaffold(backgroundColor: hrBackground, appBar: hrAppBar('Xác nhận rút ngắn phép'), body: body);
  }
}

// Chi tiết yêu cầu: chọn Đúng giờ/Đi muộn cho từng buổi AwaitingHr rồi xác nhận hoặc từ chối.
class _DetailSheet extends StatefulWidget {
  final LeaveReturnRequest request;

  const _DetailSheet({required this.request});

  @override
  State<_DetailSheet> createState() => _DetailSheetState();
}

class _DetailSheetState extends State<_DetailSheet> {
  final Map<String, String> _statuses = {}; // mặc định OnTime nếu chưa chọn

  String _key(LeaveReturnSession s) => '${isoDate(s.date)}|${s.session}';

  Future<void> _confirm() async {
    final r = widget.request;
    final ok = await confirmDialog(
      context,
      title: 'Xác nhận đã đi làm',
      message: 'Xác nhận ${r.employeeName} đã đi làm lại các buổi chờ xác nhận?',
      confirmText: 'Xác nhận',
    );
    if (!ok || !mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    final nav = Navigator.of(context);
    final err = await context.read<HrReturnsProvider>().confirm(r, _statuses);
    messenger.showSnackBar(
      SnackBar(
        content: Text(err ?? 'Đã xác nhận rút ngắn nghỉ phép.'),
        backgroundColor: err == null ? Colors.green : Colors.red,
      ),
    );
    if (err == null) nav.pop();
  }

  Future<void> _reject() async {
    final r = widget.request;
    final reason = await askReason(context, title: 'Từ chối yêu cầu của ${r.employeeName}');
    if (reason == null || !mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    final nav = Navigator.of(context);
    final err = await context.read<HrReturnsProvider>().reject(r.id, reason);
    messenger.showSnackBar(
      SnackBar(content: Text(err ?? 'Đã từ chối yêu cầu.'), backgroundColor: err == null ? Colors.green : Colors.red),
    );
    if (err == null) nav.pop();
  }

  @override
  Widget build(BuildContext context) {
    final r = widget.request;
    final busy = context.watch<HrReturnsProvider>().busyId == r.id;
    final awaiting = r.sessions.where((s) => s.state == 'AwaitingHr').toList();
    final active = r.sessions.where((s) => s.state == 'Active').toList();

    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.85),
        child: ListView(
          shrinkWrap: true,
          padding: EdgeInsets.fromLTRB(16, 0, 16, 16 + MediaQuery.of(context).viewInsets.bottom),
          children: [
            Text(
              '${r.employeeName} (${r.employeeCode})',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 4),
            Text(
              'Đi làm lại từ ${sessionName(r.fromSession).toLowerCase()} ${formatDate(r.fromDate)}',
              style: const TextStyle(color: Colors.black54),
            ),
            const SizedBox(height: 8),
            Text('Lý do: ${r.reason}'),
            if (r.managerName != null)
              Text(
                'Quản lý duyệt: ${r.managerName}${r.managerApprovedAt == null ? '' : ' · ${formatDateTime(r.managerApprovedAt)}'}',
                style: const TextStyle(color: Colors.black54, fontSize: 12),
              ),
            const SizedBox(height: 16),
            const Text('Các buổi chờ xác nhận', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            if (awaiting.isEmpty)
              const Text('Không có buổi nào chờ xác nhận.', style: TextStyle(color: Colors.black54))
            else
              ...awaiting.map(
                (s) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  // Xếp dọc để nút chọn không bị bóp khi màn hẹp/chữ lớn.
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        '${formatDate(s.date)} · ${sessionName(s.session)}\n${s.leaveTypeName}',
                        style: const TextStyle(fontSize: 13),
                      ),
                      const SizedBox(height: 6),
                      SegmentedButton<String>(
                        showSelectedIcon: false,
                        segments: const [
                          ButtonSegment(value: 'OnTime', label: Text('Đúng giờ')),
                          ButtonSegment(value: 'Late', label: Text('Đi muộn')),
                        ],
                        selected: {_statuses[_key(s)] ?? 'OnTime'},
                        onSelectionChanged: (v) => setState(() => _statuses[_key(s)] = v.first),
                      ),
                    ],
                  ),
                ),
              ),
            if (active.isNotEmpty) ...[
              const SizedBox(height: 12),
              const Text('Các buổi đã có hiệu lực', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              ...active.map(
                (s) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          '${formatDate(s.date)} · ${sessionName(s.session)} · ${s.leaveTypeName}',
                          style: const TextStyle(fontSize: 13, color: Colors.black54),
                        ),
                      ),
                      if (s.workedStatus != null)
                        StatusChip(
                          label: sessionStatusLabel(s.workedStatus!),
                          color: sessionStatusColor(s.workedStatus!),
                        ),
                    ],
                  ),
                ),
              ),
            ],
            PermissionGate(
              code: 'attendance.note.manage',
              child: Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(onPressed: busy ? null : _reject, child: const Text('Từ chối')),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 2,
                      child: FilledButton(
                        onPressed: busy || awaiting.isEmpty ? null : _confirm,
                        style: FilledButton.styleFrom(backgroundColor: hrPrimary),
                        child: busy ? busyIndicator() : const Text('Xác nhận đã đi làm'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
