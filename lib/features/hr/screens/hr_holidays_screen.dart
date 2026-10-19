import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../core/network/api_client.dart';
import '../../../models/timesheet.dart';
import '../../../services/timesheet_service.dart';
import '../../../shared/widgets/confirm_dialog.dart';
import '../../../shared/widgets/permission_gate.dart';
import '../../../shared/widgets/state_views.dart';

// Ngày nghỉ lễ (route /hr/holidays, quyền holiday.manage): các ngày không phải ngày làm việc của công ty.
// Ngày lễ không bị tính vắng, không tính vào ngày nghỉ phép và không xin nghỉ được.
class HrHolidaysScreen extends StatelessWidget {
  const HrHolidaysScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (ctx) => HolidaysProvider(TimesheetService(ctx.read<ApiClient>()))..load(),
      child: const _View(),
    );
  }
}

class HolidaysProvider extends ChangeNotifier {
  final TimesheetService _service;

  HolidaysProvider(this._service);

  int year = DateTime.now().year;
  List<Holiday> items = [];
  bool isLoading = false;
  String? error;

  Future<void> load({bool silent = false}) async {
    if (!silent) {
      isLoading = true;
      error = null;
      notifyListeners();
    }
    try {
      items = await _service.getHolidays(year);
    } catch (e) {
      if (!silent) error = e.toString().replaceFirst('Exception: ', '');
    }
    isLoading = false;
    notifyListeners();
  }

  Future<void> shiftYear(int delta) {
    year += delta;
    items = [];
    return load();
  }

  // null = thành công, ngược lại là thông báo lỗi nguyên văn.
  Future<String?> add(DateTime date, String name) => _run(() => _service.createHoliday(date, name));

  Future<String?> remove(int id) => _run(() => _service.deleteHoliday(id));

  Future<String?> _run(Future<void> Function() action) async {
    String? err;
    try {
      await action();
    } catch (e) {
      err = e.toString().replaceFirst('Exception: ', '');
    }
    if (err == null) await load(silent: true);
    return err;
  }
}

class _View extends StatelessWidget {
  const _View();

  static String _weekday(DateTime d) =>
      const ['Thứ Hai', 'Thứ Ba', 'Thứ Tư', 'Thứ Năm', 'Thứ Sáu', 'Thứ Bảy', 'Chủ nhật'][d.weekday - 1];

  Future<void> _add(BuildContext context) async {
    final p = context.read<HolidaysProvider>();
    final result = await showDialog<(DateTime, String)>(
      context: context,
      builder: (_) => _AddDialog(year: p.year),
    );
    if (result == null || !context.mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    final err = await p.add(result.$1, result.$2);
    messenger.showSnackBar(SnackBar(content: Text(err ?? 'Đã thêm ngày lễ.'), backgroundColor: err == null ? Colors.green : Colors.red));
  }

  Future<void> _remove(BuildContext context, Holiday h) async {
    final ok = await confirmDialog(
      context,
      title: 'Xóa ngày lễ',
      message: 'Xóa "${h.name}" (${DateFormat('dd/MM/yyyy').format(h.date)})? Ngày này sẽ trở lại là ngày làm việc bình thường.',
      confirmText: 'Xóa',
      danger: true,
    );
    if (!ok || !context.mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    final err = await context.read<HolidaysProvider>().remove(h.id);
    messenger.showSnackBar(SnackBar(content: Text(err ?? 'Đã xóa ngày lễ.'), backgroundColor: err == null ? Colors.green : Colors.red));
  }

  @override
  Widget build(BuildContext context) {
    final p = context.watch<HolidaysProvider>();

    Widget body;
    if (p.isLoading && p.items.isEmpty) {
      body = const LoadingView();
    } else if (p.error != null && p.items.isEmpty) {
      body = ErrorView(message: p.error!, onRetry: p.load);
    } else {
      body = RefreshIndicator(
        onRefresh: p.load,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(12),
          children: [
            Row(
              children: [
                IconButton(icon: const Icon(Icons.chevron_left), onPressed: () => p.shiftYear(-1)),
                Expanded(
                  child: Text('Năm ${p.year}', textAlign: TextAlign.center, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ),
                IconButton(icon: const Icon(Icons.chevron_right), onPressed: () => p.shiftYear(1)),
              ],
            ),
            if (p.items.isEmpty)
              const Padding(
                padding: EdgeInsets.only(top: 40),
                child: EmptyView(message: 'Chưa khai báo ngày lễ nào cho năm này.', icon: Icons.event_busy),
              )
            else
              for (final h in p.items)
                Card(
                  elevation: 0,
                  color: Colors.white,
                  margin: const EdgeInsets.only(bottom: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: ListTile(
                    leading: const Icon(Icons.celebration_outlined, color: Color(0xFF5A3FD8)),
                    title: Text(h.name),
                    subtitle: Text('${_weekday(h.date)}, ${DateFormat('dd/MM/yyyy').format(h.date)}'),
                    trailing: PermissionGate(
                      code: 'holiday.manage',
                      child: IconButton(
                        tooltip: 'Xóa',
                        icon: const Icon(Icons.delete_outline, color: Colors.red),
                        onPressed: () => _remove(context, h),
                      ),
                    ),
                  ),
                ),
          ],
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF6F4FC),
      appBar: AppBar(
        title: const Text('Ngày nghỉ lễ'),
        backgroundColor: const Color(0xFF5A3FD8),
        foregroundColor: Colors.white,
      ),
      floatingActionButton: PermissionGate(
        code: 'holiday.manage',
        child: FloatingActionButton.extended(
          backgroundColor: const Color(0xFF5A3FD8),
          foregroundColor: Colors.white,
          onPressed: () => _add(context),
          icon: const Icon(Icons.add),
          label: const Text('Thêm ngày lễ'),
        ),
      ),
      body: body,
    );
  }
}

class _AddDialog extends StatefulWidget {
  final int year;
  const _AddDialog({required this.year});

  @override
  State<_AddDialog> createState() => _AddDialogState();
}

class _AddDialogState extends State<_AddDialog> {
  final _name = TextEditingController();
  late DateTime _date = DateTime(widget.year, DateTime.now().month.clamp(1, 12), 1);

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _pick() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => _date = picked);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Thêm ngày lễ'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          InkWell(
            onTap: _pick,
            child: InputDecorator(
              decoration: const InputDecoration(labelText: 'Ngày', border: OutlineInputBorder(), prefixIcon: Icon(Icons.event)),
              child: Text(DateFormat('dd/MM/yyyy').format(_date)),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _name,
            maxLength: 200,
            decoration: const InputDecoration(labelText: 'Tên ngày lễ', border: OutlineInputBorder()),
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Huỷ')),
        TextButton(
          onPressed: () {
            final name = _name.text.trim();
            if (name.isEmpty) return;
            Navigator.pop(context, (_date, name));
          },
          child: const Text('Thêm'),
        ),
      ],
    );
  }
}
