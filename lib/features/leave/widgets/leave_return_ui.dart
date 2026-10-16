import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../core/network/api_client.dart';
import '../../../models/attendance_hr.dart';
import '../../../services/hr_service.dart';
import '../../../shared/widgets/confirm_dialog.dart';
import '../../../shared/widgets/permission_gate.dart';
import '../../../shared/widgets/state_views.dart';
import '../../../shared/widgets/status_chip.dart';
import '../../attendance/widgets/capped_width.dart';

// Nhãn và màu cho yêu cầu đi làm lại, dùng chung giữa màn nhân viên và màn Manager.
const Map<String, String> returnStatusLabels = {
  'PendingManager': 'Chờ quản lý duyệt',
  'PendingHr': 'Chờ xác nhận',
  'Completed': 'Hoàn tất',
  'Rejected': 'Từ chối',
};

const Map<String, String> returnSessionStateLabels = {
  'Pending': 'Chờ quản lý duyệt',
  'AwaitingHr': 'Chờ xác nhận',
  'Active': 'Đã có hiệu lực',
  'Rejected': 'Từ chối',
};

Color returnStatusColor(String status) {
  switch (status) {
    case 'PendingManager':
    case 'Pending':
      return StatusChip.warning;
    case 'PendingHr':
    case 'AwaitingHr':
      return StatusChip.info;
    case 'Completed':
    case 'Active':
      return StatusChip.success;
    case 'Rejected':
      return StatusChip.danger;
    default:
      return StatusChip.neutral;
  }
}

String sessionName(String session) => session == 'Morning' ? 'Sáng' : 'Chiều';

String _dayText(DateTime d) => DateFormat('dd/MM/yyyy').format(d);

// Danh sách các buổi (ngày, buổi, đơn nghỉ gốc, trạng thái từng buổi).
class ReturnSessionList extends StatelessWidget {
  final List<LeaveReturnSession> sessions;
  final bool showState;

  const ReturnSessionList({super.key, required this.sessions, this.showState = true});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final s in sessions)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 3),
            child: Row(
              children: [
                const Icon(Icons.schedule, size: 16, color: Colors.grey),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${_dayText(s.date)} · ${sessionName(s.session)} · đơn #${s.leaveRequestId}'
                    '${s.workedStatus == null ? '' : ' · ${s.workedStatus == 'Late' ? 'đi muộn' : 'đúng giờ'}'}',
                    style: const TextStyle(fontSize: 13),
                  ),
                ),
                if (showState)
                  CappedWidth(
                    child: StatusChip(
                      label: returnSessionStateLabels[s.state] ?? s.state,
                      color: returnStatusColor(s.state),
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }
}

// Thẻ một yêu cầu đi làm lại. [actions] (nếu có) hiện ở cuối thẻ (nút Duyệt/Từ chối của Manager).
class ReturnRequestCard extends StatelessWidget {
  final LeaveReturnRequest request;
  final bool showEmployee;
  final Widget? actions;

  const ReturnRequestCard({super.key, required this.request, this.showEmployee = false, this.actions});

  @override
  Widget build(BuildContext context) {
    final r = request;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    showEmployee ? r.employeeName : 'Đi làm lại từ ${_dayText(r.fromDate)} (${sessionName(r.fromSession)})',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF5A3FD8)),
                  ),
                ),
                CappedWidth(
                  child: StatusChip(label: returnStatusLabels[r.status] ?? r.status, color: returnStatusColor(r.status)),
                ),
              ],
            ),
            const Divider(),
            if (showEmployee) Text('Đi làm lại từ: ${_dayText(r.fromDate)} (${sessionName(r.fromSession)})'),
            Text('Lý do: ${r.reason}', style: const TextStyle(color: Colors.black54)),
            const SizedBox(height: 8),
            ReturnSessionList(sessions: r.sessions),
            if (r.status == 'Rejected' && (r.rejectionReason ?? '').isNotEmpty) ...[
              const SizedBox(height: 6),
              Text('Lý do từ chối: ${r.rejectionReason}', style: const TextStyle(color: StatusChip.danger)),
            ],
            if ((r.managerName ?? '').isNotEmpty)
              Text('Quản lý: ${r.managerName}', style: const TextStyle(color: Colors.grey, fontSize: 12)),
            if ((r.processedByName ?? '').isNotEmpty)
              Text('Người xác nhận: ${r.processedByName}', style: const TextStyle(color: Colors.grey, fontSize: 12)),
            if (actions != null) ...[const SizedBox(height: 12), actions!],
          ],
        ),
      ),
    );
  }
}

// Tab "Đi làm lại" trong màn Duyệt đơn nghỉ: Manager duyệt hoặc từ chối yêu cầu của nhân viên mình quản lý.
class PendingReturnsTab extends StatefulWidget {
  const PendingReturnsTab({super.key});

  @override
  State<PendingReturnsTab> createState() => _PendingReturnsTabState();
}

class _PendingReturnsTabState extends State<PendingReturnsTab> {
  late final HrService _service;
  List<LeaveReturnRequest> _items = [];
  bool _loading = true;
  String? _error;
  int? _busyId;

  @override
  void initState() {
    super.initState();
    _service = HrService(context.read<ApiClient>());
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final items = await _service.getPendingReturns();
      if (!mounted) return;
      setState(() => _items = items..sort((a, b) => b.id.compareTo(a.id)));
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _run(LeaveReturnRequest r, Future<void> Function() action, String okMessage) async {
    setState(() => _busyId = r.id);
    String? error;
    try {
      await action();
    } catch (e) {
      error = e.toString().replaceFirst('Exception: ', '');
    }
    if (!mounted) return;
    setState(() => _busyId = null);
    showMessage(context, error ?? okMessage, error: error != null);
    await _load(); // tải lại để bỏ yêu cầu đã được xử lý
  }

  Future<void> _approve(LeaveReturnRequest r) async {
    final ok = await confirmDialog(
      context,
      title: 'Duyệt yêu cầu đi làm lại',
      message: 'Duyệt yêu cầu của ${r.employeeName}?\n\n'
          'Buổi chưa tới giờ bắt đầu sẽ có hiệu lực ngay (phần ngày phép được hoàn lại). '
          'Buổi đã bắt đầu sẽ chuyển sang HR xác nhận.',
      confirmText: 'Duyệt',
    );
    if (!ok || !mounted) return;
    await _run(r, () => _service.approveReturn(r.id), 'Đã duyệt yêu cầu đi làm lại.');
  }

  Future<void> _reject(LeaveReturnRequest r) async {
    final controller = TextEditingController();
    final reason = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Từ chối yêu cầu đi làm lại'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Yêu cầu của ${r.employeeName}'),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              maxLines: 3,
              decoration: const InputDecoration(border: OutlineInputBorder(), labelText: 'Lý do từ chối'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Hủy')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: const Text('Từ chối', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    controller.dispose();
    if (reason == null || !mounted) return;
    await _run(r, () => _service.rejectReturn(r.id, reason: reason.isEmpty ? null : reason), 'Đã từ chối yêu cầu.');
  }

  @override
  Widget build(BuildContext context) {
    if (_loading && _items.isEmpty) return const LoadingView();
    if (_error != null && _items.isEmpty) return ErrorView(message: _error!, onRetry: _load);

    return RefreshIndicator(
      onRefresh: _load,
      child: _items.isEmpty
          ? ListView(children: const [
              SizedBox(height: 100),
              EmptyView(message: 'Không có yêu cầu đi làm lại chờ duyệt', icon: Icons.work_history_outlined),
            ])
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _items.length,
              itemBuilder: (context, i) {
                final r = _items[i];
                final busy = _busyId == r.id;
                return ReturnRequestCard(
                  request: r,
                  showEmployee: true,
                  actions: PermissionGate(
                    code: 'leave.request.approve',
                    child: Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: busy ? null : () => _reject(r),
                            child: const Text('TỪ CHỐI', style: TextStyle(color: Colors.red)),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF5A3FD8)),
                            onPressed: busy ? null : () => _approve(r),
                            child: busy
                                ? const SizedBox(
                                    height: 18,
                                    width: 18,
                                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                  )
                                : const Text('DUYỆT'),
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
}
