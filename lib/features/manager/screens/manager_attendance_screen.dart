import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/network/api_client.dart';
import '../../../core/utils/helpers.dart';
import '../../../models/manager_attendance.dart';
import '../../../services/manager_service.dart';
import '../../../shared/widgets/confirm_dialog.dart';
import '../../../shared/widgets/permission_gate.dart';
import '../../../shared/widgets/state_views.dart';
import '../../../shared/widgets/status_chip.dart';
import '../../auth/providers/auth_provider.dart';
import '../manager_helpers.dart';
import '../providers/manager_attendance_provider.dart';

// Quản lý chấm công (tương ứng ManagerAttendancePage): bảng công cả phòng + yêu cầu chỉnh sửa chờ duyệt.
class ManagerAttendanceScreen extends StatelessWidget {
  const ManagerAttendanceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (ctx) => ManagerAttendanceProvider(
        ManagerService(ctx.read<ApiClient>()),
        ctx.read<AuthProvider>(),
      ),
      child: const _ManagerAttendanceView(),
    );
  }
}

class _ManagerAttendanceView extends StatefulWidget {
  const _ManagerAttendanceView();

  @override
  State<_ManagerAttendanceView> createState() => _ManagerAttendanceViewState();
}

class _ManagerAttendanceViewState extends State<_ManagerAttendanceView> {
  late final bool _canTeam;
  late final bool _canPending;

  @override
  void initState() {
    super.initState();
    final auth = context.read<AuthProvider>();
    _canTeam = auth.can('attendance.view.team');
    _canPending = auth.can('attendance.adjustment.view');
    final provider = context.read<ManagerAttendanceProvider>();
    // Chỉ tải phần mà tài khoản có quyền xem.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_canTeam) provider.loadTeam();
      if (_canPending) provider.loadPending();
    });
  }

  @override
  Widget build(BuildContext context) {
    final tabs = <Tab>[
      if (_canTeam) const Tab(text: 'Chấm công team'),
      if (_canPending) const Tab(text: 'Yêu cầu chỉnh sửa'),
    ];
    final pendingCount = context.select<ManagerAttendanceProvider, int>((p) => p.pending.length);

    if (tabs.isEmpty) {
      return Scaffold(
        backgroundColor: managerBackground,
        appBar: managerAppBar('Quản lý chấm công'),
        body: const EmptyView(message: 'Bạn không có quyền xem chấm công của team.', icon: Icons.lock_outline),
      );
    }

    return DefaultTabController(
      length: tabs.length,
      child: Scaffold(
        backgroundColor: managerBackground,
        appBar: managerAppBar(
          'Quản lý chấm công',
          bottom: TabBar(
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            indicatorColor: Colors.white,
            tabs: [
              if (_canTeam) const Tab(text: 'Chấm công team'),
              if (_canPending) Tab(text: pendingCount > 0 ? 'Yêu cầu chỉnh sửa ($pendingCount)' : 'Yêu cầu chỉnh sửa'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            if (_canTeam) const _TeamTab(),
            if (_canPending) const _PendingTab(),
          ],
        ),
      ),
    );
  }
}

// ===== Tab bảng công cả phòng =====
class _TeamTab extends StatelessWidget {
  const _TeamTab();

  Future<void> _pickRange(BuildContext context, ManagerAttendanceProvider p) async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      initialDateRange: DateTimeRange(start: p.startDate, end: p.endDate),
    );
    if (picked != null) await p.setRange(picked.start, picked.end);
  }

  Future<void> _export(BuildContext context, ManagerAttendanceProvider p) async {
    final messenger = ScaffoldMessenger.of(context);
    final error = await p.exportCsv();
    if (error != null) {
      messenger.showSnackBar(SnackBar(content: Text(error), backgroundColor: Colors.red));
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.watch<ManagerAttendanceProvider>();
    final list = p.filteredRecords;

    Widget content;
    if (p.isLoadingTeam && p.records.isEmpty) {
      content = const LoadingView();
    } else if (p.teamError != null && p.records.isEmpty) {
      content = ErrorView(message: p.teamError!, onRetry: p.loadTeam);
    } else if (list.isEmpty) {
      content = const EmptyView(message: 'Chưa có bản ghi chấm công trong khoảng thời gian này.', icon: Icons.event_busy);
    } else {
      content = RefreshIndicator(
        onRefresh: p.loadTeam,
        child: ListView.separated(
          padding: const EdgeInsets.all(12),
          itemCount: list.length,
          separatorBuilder: (_, _) => const SizedBox(height: 8),
          itemBuilder: (_, i) => _RecordCard(record: list[i]),
        ),
      );
    }

    return Column(
      children: [
        Container(
          color: Colors.white,
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _pickRange(context, p),
                      icon: const Icon(Icons.date_range),
                      label: Text('${formatDate(p.startDate)} - ${formatDate(p.endDate)}'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filledTonal(
                    tooltip: 'Xuất bảng công',
                    onPressed: p.filteredRecords.isEmpty ? null : () => _export(context, p),
                    icon: const Icon(Icons.download),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String?>(
                      initialValue: p.employeeFilter,
                      isExpanded: true,
                      decoration: const InputDecoration(labelText: 'Nhân viên', isDense: true, border: OutlineInputBorder()),
                      items: [
                        const DropdownMenuItem<String?>(value: null, child: Text('Tất cả')),
                        ...p.employeeOptions.entries.map((e) => DropdownMenuItem<String?>(value: e.key, child: Text(e.value, overflow: TextOverflow.ellipsis))),
                      ],
                      onChanged: p.setEmployee,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: DropdownButtonFormField<String?>(
                      initialValue: p.statusFilter,
                      isExpanded: true,
                      decoration: const InputDecoration(labelText: 'Trạng thái', isDense: true, border: OutlineInputBorder()),
                      items: [
                        const DropdownMenuItem<String?>(value: null, child: Text('Tất cả')),
                        ...attendanceLabels.entries.map((e) => DropdownMenuItem<String?>(value: e.key, child: Text(e.value, overflow: TextOverflow.ellipsis))),
                      ],
                      onChanged: p.setStatus,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        Expanded(child: content),
      ],
    );
  }
}

class _RecordCard extends StatelessWidget {
  final ManagerAttendanceRecord record;

  const _RecordCard({required this.record});

  @override
  Widget build(BuildContext context) {
    final r = record;
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
                Expanded(child: Text(r.employeeName, style: const TextStyle(fontWeight: FontWeight.w600))),
                StatusChip(label: attendanceLabel(r.status), color: attendanceColor(r.status)),
              ],
            ),
            const SizedBox(height: 4),
            Text('${formatDate(r.attendanceDate)} · Vào ${formatTime(r.checkInTime)} · Ra ${formatTime(r.checkOutTime)}',
                style: const TextStyle(color: Colors.black54, fontSize: 13)),
            Text('Giờ làm: ${r.workingHours ?? '--'}', style: const TextStyle(color: Colors.black54, fontSize: 13)),
          ],
        ),
      ),
    );
  }
}

// ===== Tab yêu cầu điều chỉnh chờ duyệt =====
class _PendingTab extends StatelessWidget {
  const _PendingTab();

  Future<void> _review(BuildContext context, ManagerAttendanceAdjustment item, {required bool approve}) async {
    final provider = context.read<ManagerAttendanceProvider>();
    final ok = await confirmDialog(
      context,
      title: approve ? 'Duyệt yêu cầu' : 'Từ chối yêu cầu',
      message: '${approve ? 'Duyệt' : 'Từ chối'} yêu cầu chỉnh sửa công ngày ${formatDate(item.attendanceDate)} của ${item.employeeName}?',
      confirmText: approve ? 'Duyệt' : 'Từ chối',
      danger: !approve,
    );
    if (!ok || !context.mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    final error = await provider.review(item.id, approve: approve);
    messenger.showSnackBar(SnackBar(
      content: Text(error ?? (approve ? 'Đã duyệt yêu cầu.' : 'Đã từ chối yêu cầu.')),
      backgroundColor: error == null ? Colors.green : Colors.red,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final p = context.watch<ManagerAttendanceProvider>();

    if (p.isLoadingPending && p.pending.isEmpty) return const LoadingView();
    if (p.pendingError != null && p.pending.isEmpty) {
      return ErrorView(message: p.pendingError!, onRetry: p.loadPending);
    }
    if (p.pending.isEmpty) {
      return RefreshIndicator(
        onRefresh: p.loadPending,
        child: ListView(children: const [
          SizedBox(height: 80),
          EmptyView(message: 'Mọi yêu cầu chỉnh sửa chấm công đã được xử lý.', icon: Icons.task_alt),
        ]),
      );
    }

    return RefreshIndicator(
      onRefresh: p.loadPending,
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(12),
        itemCount: p.pending.length,
        separatorBuilder: (_, _) => const SizedBox(height: 8),
        itemBuilder: (ctx, i) {
          final item = p.pending[i];
          final busy = p.busyId == item.id;
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
                      Expanded(child: Text(item.employeeName, style: const TextStyle(fontWeight: FontWeight.w600))),
                      Text(formatDate(item.attendanceDate), style: const TextStyle(color: Colors.black54)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(item.reason),
                  const SizedBox(height: 6),
                  Text(
                    'Đề xuất: ${formatDateTime(item.newCheckInTime)} - ${formatDateTime(item.newCheckOutTime)}',
                    style: const TextStyle(color: Colors.black54, fontSize: 13),
                  ),
                  PermissionGate(
                    code: 'attendance.adjustment.approve',
                    child: Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          OutlinedButton(
                            onPressed: busy ? null : () => _review(ctx, item, approve: false),
                            child: const Text('Từ chối'),
                          ),
                          const SizedBox(width: 8),
                          FilledButton(
                            onPressed: busy ? null : () => _review(ctx, item, approve: true),
                            style: FilledButton.styleFrom(backgroundColor: managerPrimary),
                            child: busy
                                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                : const Text('Duyệt'),
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
}
