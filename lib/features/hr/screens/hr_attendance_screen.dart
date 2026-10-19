import '../../../services/live_updates.dart';
import '../../../shared/widgets/auto_refresh.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/network/api_client.dart';
import '../../../core/utils/helpers.dart';
import '../../../models/attendance_record.dart';
import '../../../services/admin_service.dart';
import '../../../services/hr_service.dart';
import '../../../shared/widgets/state_views.dart';
import '../../../shared/widgets/status_chip.dart';
import '../hr_helpers.dart';
import '../providers/hr_attendance_provider.dart';

// Chấm công toàn công ty (route /hr/attendance, quyền attendance.view.all).
class HrAttendanceScreen extends StatelessWidget {
  const HrAttendanceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (ctx) {
        final api = ctx.read<ApiClient>();
        return HrAttendanceProvider(HrService(api), AdminService(api))..init();
      },
      child: const _View(),
    );
  }
}

class _View extends StatelessWidget {
  const _View();

  Future<void> _pickRange(BuildContext context, HrAttendanceProvider p) async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      initialDateRange: DateTimeRange(start: p.startDate, end: p.endDate),
    );
    if (picked != null) await p.setRange(picked.start, picked.end);
  }

  Future<void> _export(BuildContext context, HrAttendanceProvider p) async {
    final messenger = ScaffoldMessenger.of(context);
    final error = await p.exportCsv();
    if (error != null) messenger.showSnackBar(SnackBar(content: Text(error), backgroundColor: Colors.red));
  }

  @override
  Widget build(BuildContext context) {
    return AutoRefresh(
      onRefresh: () => context.read<HrAttendanceProvider>().load(silent: true),
      types: NotificationTypes.hr,
      child: _buildContent(context),
    );
  }

  Widget _buildContent(BuildContext context) {
    final p = context.watch<HrAttendanceProvider>();
    final list = p.filtered;

    Widget content;
    if (p.isLoading && p.records.isEmpty) {
      content = const LoadingView();
    } else if (p.error != null && p.records.isEmpty) {
      content = ErrorView(message: p.error!, onRetry: p.load);
    } else {
      content = RefreshIndicator(
        onRefresh: p.load,
        child: list.isEmpty
            ? ListView(
                children: const [
                  SizedBox(height: 80),
                  EmptyView(message: 'Không có bản ghi chấm công trong khoảng này.', icon: Icons.event_busy),
                ],
              )
            : ListView.separated(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(12),
                itemCount: list.length,
                separatorBuilder: (_, _) => const SizedBox(height: 8),
                itemBuilder: (_, i) => _RecordCard(record: list[i]),
              ),
      );
    }

    return Scaffold(
      backgroundColor: hrBackground,
      appBar: hrAppBar('Chấm công toàn công ty'),
      body: Column(
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
                      tooltip: 'Xuất CSV',
                      onPressed: p.filtered.isEmpty ? null : () => _export(context, p),
                      icon: const Icon(Icons.download),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        onChanged: p.setSearch,
                        decoration: const InputDecoration(
                          hintText: 'Tìm tên hoặc mã NV',
                          prefixIcon: Icon(Icons.search),
                          isDense: true,
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: DropdownButtonFormField<String?>(
                        initialValue: p.departmentCode,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          labelText: 'Phòng ban',
                          isDense: true,
                          border: OutlineInputBorder(),
                        ),
                        items: [
                          const DropdownMenuItem<String?>(value: null, child: Text('Tất cả')),
                          ...p.departments.map(
                            (d) => DropdownMenuItem<String?>(
                              value: d.departmentCode,
                              child: Text(d.departmentName, overflow: TextOverflow.ellipsis),
                            ),
                          ),
                        ],
                        onChanged: p.setDepartment,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (p.isLoading && p.records.isNotEmpty) const LinearProgressIndicator(minHeight: 2),
          Expanded(child: content),
        ],
      ),
    );
  }
}

class _RecordCard extends StatelessWidget {
  final AttendanceRecord record;

  const _RecordCard({required this.record});

  @override
  Widget build(BuildContext context) {
    final r = record;
    final day = parseDay(r.attendanceDate);
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
                Expanded(
                  child: Text(
                    '${r.employeeName} (${r.employeeCode})',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
                Text(formatDate(day), style: const TextStyle(color: Colors.black54)),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Vào ${formatTime(r.checkInTime)} · Ra ${formatTime(r.checkOutTime)}',
              style: const TextStyle(color: Colors.black54, fontSize: 13),
            ),
            if (r.leaveTypeName != null && r.leaveTypeName!.isNotEmpty)
              Text('Nghỉ phép: ${r.leaveTypeName}', style: const TextStyle(color: Colors.black54, fontSize: 13)),
            const SizedBox(height: 8),
            _SessionTile(label: 'Sáng', status: r.morningStatus, source: r.morningSource, note: r.morningNote),
            const SizedBox(height: 4),
            _SessionTile(label: 'Chiều', status: r.afternoonStatus, source: r.afternoonSource, note: r.afternoonNote),
          ],
        ),
      ),
    );
  }
}

// Một buổi: chip trạng thái + biểu tượng khi nguồn là ghi chú HR / xác nhận đi làm lại.
class _SessionTile extends StatelessWidget {
  final String label;
  final String status;
  final String source;
  final String? note;

  const _SessionTile({required this.label, required this.status, required this.source, this.note});

  @override
  Widget build(BuildContext context) {
    IconData? icon;
    String? tip;
    if (source == 'Note') {
      icon = Icons.edit_note;
      tip = 'Ghi chú HR';
    } else if (source == 'ReturnConfirmed') {
      icon = Icons.assignment_turned_in_outlined;
      tip = 'Xác nhận rút ngắn phép';
    }
    final hasNote = note != null && note!.isNotEmpty;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        ConstrainedBox(
          constraints: const BoxConstraints(minWidth: 44),
          child: Text('$label:', style: const TextStyle(fontSize: 13, color: Colors.black54)),
        ),
        const SizedBox(width: 4),
        StatusChip(label: sessionStatusLabel(status), color: sessionStatusColor(status)),
        if (icon != null) ...[
          const SizedBox(width: 6),
          Tooltip(
            message: tip!,
            child: Icon(icon, size: 18, color: hrPrimary),
          ),
        ],
        if (hasNote) ...[
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              note!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12, color: Colors.black54),
            ),
          ),
        ],
      ],
    );
  }
}
