import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/network/api_client.dart';
import '../../../core/utils/helpers.dart';
import '../../../models/timesheet.dart';
import '../../../services/timesheet_service.dart';
import '../../../shared/widgets/confirm_dialog.dart';
import '../../../shared/widgets/permission_gate.dart';
import '../../../shared/widgets/state_views.dart';
import '../../../shared/widgets/status_chip.dart';
import '../providers/hr_timesheet_provider.dart';

// Bảng công tháng (route /hr/timesheet, quyền timesheet.manage): tổng hợp công của từng nhân viên trong tháng,
// chốt kỳ công (khóa dữ liệu của tháng) hoặc mở lại, xuất CSV để tính lương.
class HrTimesheetScreen extends StatelessWidget {
  // team = true: dùng cho quản lý (route /manager/timesheet), chỉ gồm cấp dưới của mình; chốt/mở lại bị ẩn vì thiếu quyền timesheet.manage.
  final bool team;
  const HrTimesheetScreen({super.key, this.team = false});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (ctx) => HrTimesheetProvider(TimesheetService(ctx.read<ApiClient>()), team: team)..load(),
      child: const _View(),
    );
  }
}

class _View extends StatelessWidget {
  const _View();

  Future<void> _close(BuildContext context, HrTimesheetProvider p) async {
    final ok = await confirmDialog(
      context,
      title: 'Chốt bảng công',
      message: 'Sau khi chốt tháng ${p.month}/${p.year}, không ai được thêm hoặc sửa dữ liệu công của tháng này '
          '(điều chỉnh, ghi nhận, nghỉ phép, làm thêm giờ...). Bạn có thể mở lại khi cần. Chốt bảng công?',
      confirmText: 'Chốt',
    );
    if (!ok || !context.mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    final err = await p.close();
    messenger.showSnackBar(SnackBar(content: Text(err ?? 'Đã chốt bảng công.'), backgroundColor: err == null ? Colors.green : Colors.red));
  }

  Future<void> _reopen(BuildContext context, HrTimesheetProvider p) async {
    final ok = await confirmDialog(
      context,
      title: 'Mở lại bảng công',
      message: 'Mở lại tháng ${p.month}/${p.year} cho phép sửa dữ liệu công của tháng này. Mở lại?',
      confirmText: 'Mở lại',
      danger: true,
    );
    if (!ok || !context.mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    final err = await p.reopen();
    messenger.showSnackBar(SnackBar(content: Text(err ?? 'Đã mở lại bảng công.'), backgroundColor: err == null ? Colors.green : Colors.red));
  }

  Future<void> _export(BuildContext context, HrTimesheetProvider p) async {
    final messenger = ScaffoldMessenger.of(context);
    final err = await p.exportCsv();
    if (err != null) messenger.showSnackBar(SnackBar(content: Text(err), backgroundColor: Colors.red));
  }

  @override
  Widget build(BuildContext context) {
    final p = context.watch<HrTimesheetProvider>();
    final sheet = p.sheet;

    Widget body;
    if (p.isLoading && sheet == null) {
      body = const LoadingView();
    } else if (p.error != null && sheet == null) {
      body = ErrorView(message: p.error!, onRetry: p.load);
    } else {
      final rows = p.filtered;
      body = RefreshIndicator(
        onRefresh: p.load,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(12),
          children: [
            if (sheet != null) _statusCard(context, p, sheet),
            const SizedBox(height: 8),
            TextField(
              onChanged: p.setSearch,
              decoration: const InputDecoration(
                hintText: 'Tìm theo tên / mã nhân viên',
                prefixIcon: Icon(Icons.search),
                isDense: true,
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            if (rows.isEmpty)
              const Padding(padding: EdgeInsets.only(top: 40), child: EmptyView(message: 'Không có nhân viên nào.', icon: Icons.table_chart_outlined))
            else
              for (final r in rows) _rowCard(r),
          ],
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF6F4FC),
      appBar: AppBar(
        title: const Text('Bảng công tháng'),
        backgroundColor: const Color(0xFF5A3FD8),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            tooltip: 'Xuất CSV',
            icon: const Icon(Icons.ios_share),
            onPressed: sheet == null ? null : () => _export(context, p),
          ),
        ],
      ),
      body: body,
    );
  }

  Widget _statusCard(BuildContext context, HrTimesheetProvider p, Timesheet sheet) {
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                IconButton(icon: const Icon(Icons.chevron_left), onPressed: p.isBusy ? null : () => p.shiftMonth(-1)),
                Expanded(
                  child: Text(
                    'Tháng ${p.month.toString().padLeft(2, '0')}/${p.year}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                IconButton(icon: const Icon(Icons.chevron_right), onPressed: p.isBusy ? null : () => p.shiftMonth(1)),
              ],
            ),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text('Công chuẩn: ${sheet.standardDays} ngày'),
                StatusChip(
                  label: sheet.isClosed ? 'Đã chốt' : 'Chưa chốt',
                  color: sheet.isClosed ? StatusChip.success : StatusChip.warning,
                ),
              ],
            ),
            if (sheet.isClosed)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  'Chốt bởi ${sheet.closedByName ?? ''} lúc ${formatDateTime(sheet.closedAt?.toLocal())}',
                  style: const TextStyle(fontSize: 12.5, color: Colors.black54),
                ),
              ),
            PermissionGate(
              code: 'timesheet.manage',
              child: Padding(
                padding: const EdgeInsets.only(top: 8),
                child: sheet.isClosed
                    ? OutlinedButton.icon(
                        onPressed: p.isBusy ? null : () => _reopen(context, p),
                        icon: const Icon(Icons.lock_open),
                        label: const Text('Mở lại bảng công'),
                      )
                    : ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF5A3FD8), foregroundColor: Colors.white),
                        onPressed: p.isBusy || p.isCurrentOrFuture ? null : () => _close(context, p),
                        icon: const Icon(Icons.lock_outline),
                        label: Text(p.isCurrentOrFuture ? 'Chỉ chốt được tháng đã kết thúc' : 'Chốt bảng công'),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _rowCard(TimesheetRow r) {
    Widget chip(String label, Color color) => StatusChip(label: label, color: color);
    return Card(
      elevation: 0,
      color: Colors.white,
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(r.employeeName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            Text('${r.employeeCode} · ${r.departmentName}', style: const TextStyle(fontSize: 12.5, color: Colors.black54)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                chip('Đi làm ${dayCountLabel(r.workedDays)}', StatusChip.success),
                if (r.leaveDays > 0) chip('Phép ${dayCountLabel(r.leaveDays)}', StatusChip.info),
                if (r.absentDays > 0) chip('Vắng ${dayCountLabel(r.absentDays)}', StatusChip.danger),
                if (r.lateSessions > 0) chip('Muộn ${r.lateSessions} buổi', StatusChip.warning),
                if (r.overtimeHours > 0) chip('OT ${dayCountLabel(r.overtimeHours)}h', const Color(0xFF5A3FD8)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
