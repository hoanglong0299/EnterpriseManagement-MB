import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../models/leave_request.dart';
import '../providers/leave_approval_provider.dart';

// Màn hình duyệt đơn nghỉ phép của quản lý (tương ứng trang "Duyệt đơn xin nghỉ" bên web).
class LeaveApprovalScreen extends StatefulWidget {
  const LeaveApprovalScreen({super.key});

  @override
  State<LeaveApprovalScreen> createState() => _LeaveApprovalScreenState();
}

class _LeaveApprovalScreenState extends State<LeaveApprovalScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<LeaveApprovalProvider>().load();
    });
  }

  Future<void> _report(Future<bool> action, String successMessage) async {
    final provider = context.read<LeaveApprovalProvider>();
    final messenger = ScaffoldMessenger.of(context);
    final success = await action;
    if (!mounted) return;
    messenger.showSnackBar(
      SnackBar(
        content: Text(success ? successMessage : (provider.errorMessage ?? 'Không thể xử lý đơn nghỉ phép.')),
        backgroundColor: success ? Colors.green : Colors.red,
      ),
    );
  }

  Future<void> _approve(LeaveRequest item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Duyệt đơn nghỉ phép'),
        content: Text('Duyệt đơn nghỉ của ${item.employeeName} (${item.dateLabel})?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Hủy', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Duyệt'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    await _report(context.read<LeaveApprovalProvider>().approve(item.id), 'Đã duyệt đơn nghỉ phép.');
  }

  Future<void> _reject(LeaveRequest item) async {
    final reason = await showDialog<String>(
      context: context,
      builder: (_) => _RejectDialog(employeeName: item.employeeName),
    );
    if (reason == null || !mounted) return;
    await _report(context.read<LeaveApprovalProvider>().reject(item.id, reason), 'Đã từ chối đơn nghỉ phép.');
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<LeaveApprovalProvider>();

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F7FA),
        appBar: AppBar(
          title: const Text('Duyệt đơn xin nghỉ'),
          backgroundColor: const Color(0xFF2A5CAA),
          foregroundColor: Colors.white,
          bottom: TabBar(
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            indicatorColor: Colors.white,
            tabs: [
              Tab(text: 'Chờ duyệt (${provider.pending.length})'),
              const Tab(text: 'Lịch sử'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildList(provider, provider.pending, pending: true),
            _buildList(provider, provider.history, pending: false),
          ],
        ),
      ),
    );
  }

  Widget _buildList(LeaveApprovalProvider provider, List<LeaveRequest> items, {required bool pending}) {
    if (provider.isLoading && provider.pending.isEmpty && provider.history.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    return RefreshIndicator(
      onRefresh: provider.load,
      child: items.isEmpty
          ? ListView(
              children: [
                const SizedBox(height: 120),
                Center(
                  child: Text(
                    provider.errorMessage ?? (pending ? 'Không có đơn chờ duyệt' : 'Chưa có lịch sử'),
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.grey, fontSize: 16, fontStyle: FontStyle.italic),
                  ),
                ),
              ],
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: items.length,
              itemBuilder: (context, index) => _buildCard(provider, items[index], pending: pending),
            ),
    );
  }

  Widget _buildCard(LeaveApprovalProvider provider, LeaveRequest item, {required bool pending}) {
    final busy = provider.busyId == item.id;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    item.employeeName,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF2A5CAA)),
                  ),
                ),
                Text(item.statusLabel, style: const TextStyle(color: Colors.grey, fontSize: 12)),
              ],
            ),
            const Divider(),
            const SizedBox(height: 4),
            Text('Loại nghỉ: ${item.leaveTypeName}'),
            Text('Ngày nghỉ: ${item.dateLabel}'),
            Text('Thời gian: ${item.timeLabel} · ${item.durationLabel}'),
            const SizedBox(height: 4),
            Text('Lý do: ${item.reason ?? ''}', style: const TextStyle(color: Colors.black54)),
            if (item.status == 'Rejected' && (item.rejectionReason ?? '').isNotEmpty)
              Text('Lý do từ chối: ${item.rejectionReason}', style: const TextStyle(color: Colors.black54)),
            if (pending) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: busy ? null : () => _reject(item),
                      child: const Text('TỪ CHỐI', style: TextStyle(color: Colors.red)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2A5CAA)),
                      onPressed: busy ? null : () => _approve(item),
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
            ],
          ],
        ),
      ),
    );
  }
}

// Hộp thoại nhập lý do từ chối (không bắt buộc, giống bản web). Trả về lý do khi xác nhận, null khi hủy.
class _RejectDialog extends StatefulWidget {
  final String employeeName;
  const _RejectDialog({required this.employeeName});

  @override
  State<_RejectDialog> createState() => _RejectDialogState();
}

class _RejectDialogState extends State<_RejectDialog> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Từ chối đơn nghỉ phép'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Đơn của ${widget.employeeName}'),
          const SizedBox(height: 12),
          TextField(
            controller: _controller,
            maxLines: 3,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              labelText: 'Lý do từ chối (không bắt buộc)',
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Hủy', style: TextStyle(color: Colors.grey)),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, _controller.text),
          child: const Text('Xác nhận từ chối', style: TextStyle(color: Colors.red)),
        ),
      ],
    );
  }
}
