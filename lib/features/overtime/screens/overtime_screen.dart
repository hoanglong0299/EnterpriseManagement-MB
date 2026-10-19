import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../core/network/api_client.dart';
import '../../../models/overtime.dart';
import '../../../services/live_updates.dart';
import '../../../services/overtime_service.dart';
import '../../../shared/widgets/auto_refresh.dart';
import '../../../shared/widgets/confirm_dialog.dart';
import '../../../shared/widgets/state_views.dart';
import '../../../shared/widgets/wheel_time_picker.dart';
import '../providers/overtime_provider.dart';
import '../widgets/overtime_ui.dart';

// Làm thêm giờ (route /employee/overtime): hạn mức theo luật, form xin OT và các đơn của tôi.
// Đơn được quản lý duyệt như đơn nghỉ; đơn đã duyệt được cộng vào công của chính ngày đó.
class OvertimeScreen extends StatelessWidget {
  const OvertimeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (ctx) => OvertimeProvider(OvertimeService(ctx.read<ApiClient>()))..load(),
      child: const _View(),
    );
  }
}

class _View extends StatefulWidget {
  const _View();

  @override
  State<_View> createState() => _ViewState();
}

class _ViewState extends State<_View> {
  final _reason = TextEditingController();
  DateTime _date = DateTime.now();
  TimeOfDay _start = const TimeOfDay(hour: 17, minute: 30);
  TimeOfDay _end = const TimeOfDay(hour: 19, minute: 30);

  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  // Không dùng DateFormat('EEEE', 'vi') vì cần nạp dữ liệu locale trước.
  static String _weekday(DateTime d) =>
      const ['Thứ Hai', 'Thứ Ba', 'Thứ Tư', 'Thứ Năm', 'Thứ Sáu', 'Thứ Bảy', 'Chủ nhật'][d.weekday - 1];

  String _hhmm(TimeOfDay t) => '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  Future<void> _pickDate() async {
    final today = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(today.year, today.month, today.day),
      lastDate: today.add(const Duration(days: 30)),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _pickTime({required bool start}) async {
    final picked = await showWheelTimePicker(
      context,
      initial: start ? _start : _end,
      title: start ? 'Giờ bắt đầu' : 'Giờ kết thúc',
    );
    if (picked == null) return;
    setState(() => start ? _start = picked : _end = picked);
  }

  Future<void> _submit() async {
    final messenger = ScaffoldMessenger.of(context);
    final provider = context.read<OvertimeProvider>();
    final err = await provider.submit(date: _date, start: _start, end: _end, reason: _reason.text);
    if (!mounted) return;
    messenger.showSnackBar(SnackBar(
      content: Text(err ?? 'Đã gửi đơn làm thêm giờ, chờ quản lý duyệt.'),
      backgroundColor: err == null ? Colors.green : Colors.red,
    ));
    if (err == null) _reason.clear();
  }

  Future<void> _cancel(OvertimeRequest r) async {
    final ok = await confirmDialog(
      context,
      title: 'Hủy đơn làm thêm giờ',
      message: 'Hủy đơn ngày ${r.dateLabel} (${r.timeLabel})?',
      confirmText: 'Hủy đơn',
      danger: true,
    );
    if (!ok || !mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    final err = await context.read<OvertimeProvider>().cancel(r.id);
    messenger.showSnackBar(SnackBar(
      content: Text(err ?? 'Đã hủy đơn.'),
      backgroundColor: err == null ? Colors.green : Colors.red,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final p = context.watch<OvertimeProvider>();

    Widget body;
    if (p.isLoading && p.items.isEmpty && p.quota == null) {
      body = const LoadingView();
    } else if (p.error != null && p.items.isEmpty && p.quota == null) {
      body = ErrorView(message: p.error!, onRetry: p.load);
    } else {
      body = RefreshIndicator(
        onRefresh: p.load,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          children: [
            if (p.quota != null) _QuotaCard(p.quota!),
            const SizedBox(height: 12),
            _buildForm(p),
            const SizedBox(height: 20),
            const Text('Đơn của tôi', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            if (p.items.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: EmptyView(message: 'Bạn chưa có đơn làm thêm giờ nào.', icon: Icons.more_time),
              )
            else
              for (final r in p.items)
                OvertimeCard(
                  request: r,
                  actions: r.status == 'Pending'
                      ? Align(
                          alignment: Alignment.centerRight,
                          child: OutlinedButton(
                            onPressed: p.busyId == r.id ? null : () => _cancel(r),
                            child: const Text('HỦY ĐƠN', style: TextStyle(color: Colors.red)),
                          ),
                        )
                      : null,
                ),
          ],
        ),
      );
    }

    return AutoRefresh(
      onRefresh: () => context.read<OvertimeProvider>().load(silent: true),
      types: NotificationTypes.employeeOvertime,
      child: Scaffold(
        backgroundColor: const Color(0xFFF6F4FC),
        appBar: AppBar(
          title: const Text('Làm thêm giờ'),
          backgroundColor: const Color(0xFF5A3FD8),
          foregroundColor: Colors.white,
        ),
        body: body,
      ),
    );
  }

  Widget _buildForm(OvertimeProvider p) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Xin làm thêm giờ', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            const Text(
              'Ngày làm việc: từ 17:00 đến 22:00, tối đa 4 giờ. Cuối tuần và ngày lễ: từ 06:00 đến 22:00, tối đa 12 giờ. '
              'Mỗi đơn từ 30 phút, theo bước 30 phút.',
              style: TextStyle(fontSize: 12.5, color: Colors.black54),
            ),
            const SizedBox(height: 12),
            _pickerTile(Icons.event, 'Ngày làm thêm', '${_weekday(_date)}, ${DateFormat('dd/MM/yyyy').format(_date)}', _pickDate),
            Row(
              children: [
                Expanded(child: _pickerTile(Icons.schedule, 'Bắt đầu', _hhmm(_start), () => _pickTime(start: true))),
                const SizedBox(width: 12),
                Expanded(child: _pickerTile(Icons.schedule, 'Kết thúc', _hhmm(_end), () => _pickTime(start: false))),
              ],
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _reason,
              maxLines: 2,
              maxLength: 500,
              decoration: const InputDecoration(border: OutlineInputBorder(), labelText: 'Lý do'),
            ),
            const SizedBox(height: 4),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF5A3FD8), foregroundColor: Colors.white),
                onPressed: p.isSubmitting ? null : _submit,
                child: p.isSubmitting
                    ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('GỬI ĐƠN'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _pickerTile(IconData icon, String label, String value, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: InputDecorator(
          decoration: InputDecoration(
            labelText: label,
            border: const OutlineInputBorder(),
            prefixIcon: Icon(icon, size: 20),
            isDense: true,
          ),
          child: Text(value, maxLines: 1, overflow: TextOverflow.ellipsis),
        ),
      ),
    );
  }
}

class _QuotaCard extends StatelessWidget {
  final OvertimeQuota quota;
  const _QuotaCard(this.quota);

  Widget _bar(String label, int used, int limit, double ratio) {
    final danger = ratio >= 0.9;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('$label: ${overtimeDurationLabel(used)} / ${limit ~/ 60} giờ', style: const TextStyle(fontSize: 13.5)),
        const SizedBox(height: 4),
        LinearProgressIndicator(
          value: ratio,
          minHeight: 6,
          borderRadius: BorderRadius.circular(3),
          color: danger ? Colors.red : const Color(0xFF5A3FD8),
          backgroundColor: Colors.black12,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Hạn mức làm thêm giờ theo luật', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 2),
            const Text('Tính cả đơn đang chờ duyệt.', style: TextStyle(fontSize: 12, color: Colors.black54)),
            const SizedBox(height: 10),
            _bar('Tháng ${quota.month}', quota.monthUsedMinutes, quota.monthLimitMinutes, quota.monthRatio),
            const SizedBox(height: 10),
            _bar('Năm ${quota.year}', quota.yearUsedMinutes, quota.yearLimitMinutes, quota.yearRatio),
          ],
        ),
      ),
    );
  }
}
