import '../../../services/live_updates.dart';
import '../../../shared/widgets/auto_refresh.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/network/api_client.dart';
import '../../../core/utils/helpers.dart';
import '../../../models/attendance_hr.dart';
import '../../../services/admin_service.dart';
import '../../../services/hr_service.dart';
import '../../../shared/widgets/confirm_dialog.dart';
import '../../../shared/widgets/state_views.dart';
import '../../../shared/widgets/status_chip.dart';
import '../hr_helpers.dart';
import '../providers/hr_notes_provider.dart';

// Ghi nhận chấm công (route /hr/attendance-notes, quyền attendance.note.manage).
class HrAttendanceNotesScreen extends StatelessWidget {
  const HrAttendanceNotesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (ctx) {
        final api = ctx.read<ApiClient>();
        return HrNotesProvider(HrService(api), AdminService(api))..init();
      },
      child: DefaultTabController(
        length: 2,
        child: Scaffold(
          backgroundColor: hrBackground,
          appBar: AppBar(
            title: const Text('Ghi nhận chấm công'),
            backgroundColor: hrPrimary,
            foregroundColor: Colors.white,
            bottom: const TabBar(
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white70,
              indicatorColor: Colors.white,
              tabs: [
                Tab(text: 'Ghi nhận'),
                Tab(text: 'Đang hiệu lực'),
              ],
            ),
          ),
          body: const TabBarView(children: [_FormTab(), _NotesTab()]),
        ),
      ),
    );
  }
}

// ===== Tab form ghi nhận =====
class _FormTab extends StatefulWidget {
  const _FormTab();

  @override
  State<_FormTab> createState() => _FormTabState();
}

class _FormTabState extends State<_FormTab> {
  final _noteController = TextEditingController();
  String? _employeeCode;
  DateTime _start = DateTime.now();
  DateTime _end = DateTime.now();
  String _session = 'FullDay'; // Morning | Afternoon | FullDay
  String _status = 'OnTime'; // mặc định Đi làm đúng giờ

  bool get _multiDay => !DateUtils.isSameDay(_start, _end);

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _pickRange() async {
    final today = DateUtils.dateOnly(DateTime.now());
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: today,
      initialDateRange: DateTimeRange(
        start: _start.isAfter(today) ? today : _start,
        end: _end.isAfter(today) ? today : _end,
      ),
    );
    if (picked == null) return;
    setState(() {
      _start = picked.start;
      _end = picked.end;
      if (_multiDay) _session = 'FullDay'; // nhiều ngày thì ép Cả ngày
    });
  }

  Future<void> _submit() async {
    if (_employeeCode == null) {
      showMessage(context, 'Vui lòng chọn nhân viên.', error: true);
      return;
    }
    final note = _noteController.text.trim();
    if (note.isEmpty) {
      showMessage(context, 'Vui lòng nhập ghi chú.', error: true);
      return;
    }
    final provider = context.read<HrNotesProvider>();
    final err = await provider.create(
      employeeCode: _employeeCode!,
      startDate: _start,
      endDate: _end,
      session: _multiDay ? 'FullDay' : _session,
      status: _status,
      note: note,
    );
    if (!mounted) return;
    if (err == null) {
      _noteController.clear();
      showMessage(context, 'Đã ghi nhận chấm công.');
    } else {
      showMessage(context, err, error: true); // nguyên văn message 400
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.watch<HrNotesProvider>();
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        DropdownMenu<String>(
          expandedInsets: EdgeInsets.zero,
          enableFilter: true,
          requestFocusOnTap: true,
          label: const Text('Nhân viên'),
          dropdownMenuEntries: p.employees
              .map((e) => DropdownMenuEntry<String>(value: e.employeeCode, label: '${e.fullName} (${e.employeeCode})'))
              .toList(),
          onSelected: (v) => setState(() => _employeeCode = v),
        ),
        const SizedBox(height: 16),
        OutlinedButton.icon(
          onPressed: _pickRange,
          icon: const Icon(Icons.date_range),
          label: Text(_multiDay ? '${formatDate(_start)} - ${formatDate(_end)}' : formatDate(_start)),
        ),
        const SizedBox(height: 16),
        const Text('Buổi', style: TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        SegmentedButton<String>(
          segments: [
            ButtonSegment(value: 'Morning', label: const Text('Sáng'), enabled: !_multiDay),
            ButtonSegment(value: 'Afternoon', label: const Text('Chiều'), enabled: !_multiDay),
            const ButtonSegment(value: 'FullDay', label: Text('Cả ngày')),
          ],
          selected: {_multiDay ? 'FullDay' : _session},
          onSelectionChanged: (s) => setState(() => _session = s.first),
        ),
        if (_multiDay)
          const Padding(
            padding: EdgeInsets.only(top: 4),
            child: Text('Nhiều ngày chỉ ghi nhận được cả ngày.', style: TextStyle(fontSize: 12, color: Colors.black54)),
          ),
        const SizedBox(height: 16),
        const Text('Trạng thái', style: TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        SegmentedButton<String>(
          segments: const [
            ButtonSegment(value: 'OnTime', label: Text('Đúng giờ')),
            ButtonSegment(value: 'Late', label: Text('Đi muộn')),
            ButtonSegment(value: 'Absent', label: Text('Vắng')),
          ],
          selected: {_status},
          onSelectionChanged: (s) => setState(() => _status = s.first),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _noteController,
          maxLines: 3,
          decoration: const InputDecoration(labelText: 'Ghi chú (bắt buộc)', border: OutlineInputBorder()),
        ),
        const SizedBox(height: 20),
        FilledButton(
          onPressed: p.isSaving ? null : _submit,
          style: FilledButton.styleFrom(backgroundColor: hrPrimary, minimumSize: const Size.fromHeight(48)),
          child: p.isSaving ? busyIndicator() : const Text('Ghi nhận'),
        ),
      ],
    );
  }
}

// ===== Tab ghi chú đang hiệu lực =====
class _NotesTab extends StatelessWidget {
  const _NotesTab();

  Future<void> _pickRange(BuildContext context, HrNotesProvider p) async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      initialDateRange: DateTimeRange(start: p.from, end: p.to),
    );
    if (picked != null) await p.setRange(picked.start, picked.end);
  }

  Future<void> _revoke(BuildContext context, AttendanceNote n) async {
    final ok = await confirmDialog(
      context,
      title: 'Thu hồi ghi chú',
      message: 'Thu hồi ghi chú ${sessionName(n.session)} ngày ${formatDate(n.date)} của ${n.employeeName}?',
      confirmText: 'Thu hồi',
      danger: true,
    );
    if (!ok || !context.mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    final err = await context.read<HrNotesProvider>().revoke(n.id);
    messenger.showSnackBar(
      SnackBar(content: Text(err ?? 'Đã thu hồi ghi chú.'), backgroundColor: err == null ? Colors.green : Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AutoRefresh(
      onRefresh: () => context.read<HrNotesProvider>().loadNotes(silent: true),
      types: NotificationTypes.hr,
      child: _buildContent(context),
    );
  }

  Widget _buildContent(BuildContext context) {
    final p = context.watch<HrNotesProvider>();

    Widget content;
    if (p.isLoading && p.notes.isEmpty) {
      content = const LoadingView();
    } else if (p.error != null && p.notes.isEmpty) {
      content = ErrorView(message: p.error!, onRetry: p.loadNotes);
    } else {
      content = RefreshIndicator(
        onRefresh: p.loadNotes,
        child: p.notes.isEmpty
            ? ListView(
                children: const [
                  SizedBox(height: 80),
                  EmptyView(message: 'Chưa có ghi chú nào trong khoảng này.', icon: Icons.edit_note),
                ],
              )
            : ListView.separated(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(12),
                itemCount: p.notes.length,
                separatorBuilder: (_, _) => const SizedBox(height: 8),
                itemBuilder: (ctx, i) {
                  final n = p.notes[i];
                  final busy = p.revokingId == n.id;
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
                                  '${n.employeeName} (${n.employeeCode})',
                                  style: const TextStyle(fontWeight: FontWeight.w600),
                                ),
                              ),
                              StatusChip(label: sessionStatusLabel(n.status), color: sessionStatusColor(n.status)),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${formatDate(n.date)} · Buổi ${sessionName(n.session).toLowerCase()}',
                            style: const TextStyle(color: Colors.black54, fontSize: 13),
                          ),
                          const SizedBox(height: 4),
                          Text(n.note),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  '${n.createdByName} · ${formatDateTime(n.createdAt)}',
                                  style: const TextStyle(color: Colors.black54, fontSize: 12),
                                ),
                              ),
                              TextButton(
                                onPressed: busy ? null : () => _revoke(ctx, n),
                                child: busy
                                    ? const SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(strokeWidth: 2),
                                      )
                                    : const Text('Thu hồi', style: TextStyle(color: Colors.red)),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
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
              OutlinedButton.icon(
                onPressed: () => _pickRange(context, p),
                icon: const Icon(Icons.date_range),
                label: Text('${formatDate(p.from)} - ${formatDate(p.to)}'),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String?>(
                key: ValueKey(p.employeeFilter),
                initialValue: p.employeeFilter,
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'Nhân viên', isDense: true, border: OutlineInputBorder()),
                items: [
                  const DropdownMenuItem<String?>(value: null, child: Text('Tất cả')),
                  ...p.employees.map(
                    (e) => DropdownMenuItem<String?>(
                      value: e.employeeCode,
                      child: Text('${e.fullName} (${e.employeeCode})', overflow: TextOverflow.ellipsis),
                    ),
                  ),
                ],
                onChanged: p.setEmployeeFilter,
              ),
            ],
          ),
        ),
        Expanded(child: content),
      ],
    );
  }
}
