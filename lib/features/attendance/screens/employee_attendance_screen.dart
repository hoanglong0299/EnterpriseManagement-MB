import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../../core/network/api_client.dart';
import '../../../core/utils/helpers.dart';
import '../../../models/attendance_adjustment.dart';
import '../../../models/attendance_record.dart';
import '../../../services/attendance_service.dart';
import '../../../shared/widgets/confirm_dialog.dart';
import '../../../shared/widgets/permission_gate.dart';
import '../../../shared/widgets/state_views.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/employee_attendance_provider.dart';
import '../widgets/attendance_status.dart';
import '../widgets/today_attendance_card.dart';

class EmployeeAttendanceScreen extends StatelessWidget {
  const EmployeeAttendanceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (ctx) => EmployeeAttendanceProvider(
        AttendanceService(ctx.read<ApiClient>()),
        ctx.read<AuthProvider>(),
      )..load(),
      child: const _AttendanceView(),
    );
  }
}

class _AttendanceView extends StatelessWidget {
  const _AttendanceView();

  Future<void> _openAdjustmentForm(BuildContext context) async {
    final provider = context.read<EmployeeAttendanceProvider>();
    final ok = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _AdjustmentForm(provider: provider),
    );
    if (ok == true && context.mounted) {
      showMessage(context, 'Đã gửi yêu cầu điều chỉnh chấm công.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<EmployeeAttendanceProvider>();

    Widget body;
    if (provider.isLoading) {
      body = const LoadingView();
    } else if (provider.errorMessage != null && provider.recordsByDate.isEmpty) {
      body = ErrorView(message: provider.errorMessage!, onRetry: provider.load);
    } else {
      body = const TabBarView(children: [_HistoryTab(), _AdjustmentsTab()]);
    }

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F7FA),
        appBar: AppBar(
          title: const Text('Chấm công của tôi'),
          backgroundColor: const Color(0xFF2A5CAA),
          foregroundColor: Colors.white,
          bottom: const TabBar(
            indicatorColor: Colors.white,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            tabs: [Tab(text: 'Lịch sử'), Tab(text: 'Yêu cầu chỉnh sửa')],
          ),
        ),
        body: body,
        floatingActionButton: PermissionGate(
          code: 'attendance.adjustment.self',
          child: FloatingActionButton.extended(
            backgroundColor: const Color(0xFF2A5CAA),
            foregroundColor: Colors.white,
            onPressed: () => _openAdjustmentForm(context),
            icon: const Icon(Icons.edit_calendar_outlined),
            label: const Text('Yêu cầu chỉnh sửa'),
          ),
        ),
      ),
    );
  }
}

// ==========================================
// Tab lịch sử: thẻ hôm nay + bộ lọc + danh sách/lịch + xuất CSV
// ==========================================
class _HistoryTab extends StatefulWidget {
  const _HistoryTab();

  @override
  State<_HistoryTab> createState() => _HistoryTabState();
}

class _HistoryTabState extends State<_HistoryTab> {
  bool _calendarView = false;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  Future<void> _pickMonth(EmployeeAttendanceProvider provider) async {
    // Chọn 1 ngày bất kỳ rồi lấy tháng của ngày đó làm bộ lọc tháng.
    final picked = await showDatePicker(
      context: context,
      initialDate: provider.monthFilter ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 366)),
      helpText: 'Chọn tháng cần xem',
    );
    if (picked != null) provider.setMonthFilter(DateTime(picked.year, picked.month));
  }

  Future<void> _export(EmployeeAttendanceProvider provider) async {
    final error = await provider.exportCsv();
    if (error != null && mounted) showMessage(context, error, error: true);
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<EmployeeAttendanceProvider>();
    final rows = provider.filteredHistory;

    return RefreshIndicator(
      onRefresh: provider.load,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        children: [
          TodayAttendanceCard(today: provider.today, onReturn: provider.load),
          const SizedBox(height: 16),
          Row(
            children: [
              const Expanded(child: Text('Lịch sử chấm công', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold))),
              SegmentedButton<bool>(
                showSelectedIcon: false,
                style: const ButtonStyle(visualDensity: VisualDensity.compact),
                segments: const [
                  ButtonSegment(value: false, icon: Icon(Icons.list)),
                  ButtonSegment(value: true, icon: Icon(Icons.calendar_month)),
                ],
                selected: {_calendarView},
                onSelectionChanged: (s) => setState(() => _calendarView = s.first),
              ),
              IconButton(
                tooltip: 'Xuất CSV',
                onPressed: () => _export(provider),
                icon: const Icon(Icons.ios_share, color: Color(0xFF2A5CAA)),
              ),
            ],
          ),
          if (provider.errorMessage != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(provider.errorMessage!, style: const TextStyle(color: Colors.red)),
            ),
          const SizedBox(height: 8),
          if (_calendarView) _buildCalendar(provider) else ..._buildList(provider, rows),
        ],
      ),
    );
  }

  List<Widget> _buildList(EmployeeAttendanceProvider provider, List<AttendanceRecord> rows) {
    final month = provider.monthFilter;
    return [
      // Bộ lọc: trạng thái + tháng.
      Wrap(
        spacing: 8,
        runSpacing: 4,
        children: [
          ChoiceChip(
            label: const Text('Tất cả'),
            selected: provider.statusFilter == null,
            onSelected: (_) => provider.setStatusFilter(null),
          ),
          for (final entry in attendanceLabels.entries)
            ChoiceChip(
              label: Text(entry.value),
              selected: provider.statusFilter == entry.key,
              onSelected: (_) => provider.setStatusFilter(provider.statusFilter == entry.key ? null : entry.key),
            ),
        ],
      ),
      const SizedBox(height: 8),
      Row(
        children: [
          ActionChip(
            avatar: const Icon(Icons.calendar_today, size: 16),
            label: Text(month == null ? 'Tất cả các tháng' : 'Tháng ${month.month}/${month.year}'),
            onPressed: () => _pickMonth(provider),
          ),
          if (month != null)
            IconButton(
              tooltip: 'Bỏ lọc tháng',
              icon: const Icon(Icons.close, size: 18),
              onPressed: () => provider.setMonthFilter(null),
            ),
          const Spacer(),
          Text(
            '${rows.length} ngày · ${provider.totalHours.toStringAsFixed(1)} giờ',
            style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
          ),
        ],
      ),
      const SizedBox(height: 8),
      if (rows.isEmpty)
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 32),
          child: EmptyView(message: 'Không có dữ liệu chấm công.'),
        )
      else
        for (final r in rows) _RecordCard(record: r),
    ];
  }

  Widget _buildCalendar(EmployeeAttendanceProvider provider) {
    final byDate = provider.recordsByDate;
    final selected = _selectedDay == null ? null : byDate[isoDate(_selectedDay!)];

    return Column(
      children: [
        Container(
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
          padding: const EdgeInsets.only(bottom: 8),
          child: TableCalendar<AttendanceRecord>(
            firstDay: DateTime(2020),
            lastDay: DateTime.now().add(const Duration(days: 366)),
            focusedDay: _focusedDay,
            startingDayOfWeek: StartingDayOfWeek.monday,
            availableCalendarFormats: const {CalendarFormat.month: 'Tháng'},
            selectedDayPredicate: (d) => _selectedDay != null && isSameDay(d, _selectedDay),
            onDaySelected: (selectedDay, focusedDay) => setState(() {
              _selectedDay = selectedDay;
              _focusedDay = focusedDay;
            }),
            onPageChanged: (d) => _focusedDay = d,
            headerStyle: HeaderStyle(
              formatButtonVisible: false,
              titleCentered: true,
              titleTextFormatter: (date, locale) => 'Tháng ${date.month}/${date.year}',
            ),
            calendarBuilders: CalendarBuilders(
              dowBuilder: (context, day) {
                const names = ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'];
                return Center(child: Text(names[day.weekday - 1], style: const TextStyle(fontSize: 12, color: Colors.grey)));
              },
              // Chấm màu theo trạng thái dưới ngày có bản ghi.
              markerBuilder: (context, day, events) {
                final r = byDate[isoDate(day)];
                if (r == null) return null;
                return Positioned(
                  bottom: 4,
                  child: Container(
                    width: 7,
                    height: 7,
                    decoration: BoxDecoration(color: attendanceColor(r.status), shape: BoxShape.circle),
                  ),
                );
              },
            ),
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 12,
          runSpacing: 4,
          children: [
            for (final s in ['Present', 'Late', 'HalfDayAbsent', 'Absent', 'OnLeave'])
              Row(mainAxisSize: MainAxisSize.min, children: [
                Container(width: 8, height: 8, decoration: BoxDecoration(color: attendanceColor(s), shape: BoxShape.circle)),
                const SizedBox(width: 4),
                Text(attendanceLabel(s), style: const TextStyle(fontSize: 11)),
              ]),
          ],
        ),
        const SizedBox(height: 12),
        if (_selectedDay != null)
          selected != null
              ? _RecordCard(record: selected)
              : Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text('Không có bản ghi ngày ${formatDate(_selectedDay)}.', style: TextStyle(color: Colors.grey.shade600)),
                ),
      ],
    );
  }
}

class _RecordCard extends StatelessWidget {
  final AttendanceRecord record;
  const _RecordCard({required this.record});

  @override
  Widget build(BuildContext context) {
    final date = DateTime.parse(record.attendanceDate);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
      child: Row(
        children: [
          Container(
            width: 52,
            padding: const EdgeInsets.symmetric(vertical: 6),
            decoration: BoxDecoration(color: const Color(0xFFF5F7FA), borderRadius: BorderRadius.circular(10)),
            child: Column(
              children: [
                Text('${date.day}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                Text('Th ${date.month}', style: const TextStyle(fontSize: 11, color: Colors.grey)),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Vào: ${formatTime(record.checkInTime)}  ·  Ra: ${formatTime(record.checkOutTime)}'),
                const SizedBox(height: 2),
                Text(
                  'Số giờ làm: ${record.workingHours?.toStringAsFixed(2) ?? '--'}',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
          AttendanceStatusChip(status: record.status),
        ],
      ),
    );
  }
}

// ==========================================
// Tab yêu cầu điều chỉnh của tôi
// ==========================================
class _AdjustmentsTab extends StatelessWidget {
  const _AdjustmentsTab();

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<EmployeeAttendanceProvider>();
    final items = provider.adjustments;

    return RefreshIndicator(
      onRefresh: provider.load,
      child: items.isEmpty
          ? ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: const [
                SizedBox(height: 80),
                EmptyView(message: 'Chưa có yêu cầu chỉnh sửa chấm công.'),
              ],
            )
          : ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
              itemCount: items.length,
              itemBuilder: (_, i) => _AdjustmentCard(item: items[i]),
            ),
    );
  }
}

class _AdjustmentCard extends StatelessWidget {
  final AttendanceAdjustment item;
  const _AdjustmentCard({required this.item});

  String _change(String label, DateTime? oldT, DateTime? newT) {
    if (newT == null) return '';
    return '$label: ${formatTime(oldT)} → ${formatTime(newT)}\n';
  }

  @override
  Widget build(BuildContext context) {
    final changes = _change('Giờ vào', item.oldCheckInTime, item.newCheckInTime) +
        _change('Giờ ra', item.oldCheckOutTime, item.newCheckOutTime);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(formatDate(DateTime.parse(item.attendanceDate)), style: const TextStyle(fontWeight: FontWeight.w600)),
              ),
              RequestStatusChip(status: item.status),
            ],
          ),
          const SizedBox(height: 6),
          if (changes.isNotEmpty) Text(changes.trimRight(), style: const TextStyle(fontSize: 13)),
          const SizedBox(height: 4),
          Text('Lý do: ${item.reason}', style: TextStyle(fontSize: 13, color: Colors.grey.shade700)),
          if (item.approverName != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                'Người xử lý: ${item.approverName}${item.approvedAt != null ? ' · ${formatDateTime(item.approvedAt)}' : ''}',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
            ),
        ],
      ),
    );
  }
}

// ==========================================
// Form gửi yêu cầu điều chỉnh (bottom sheet)
// ==========================================
class _AdjustmentForm extends StatefulWidget {
  final EmployeeAttendanceProvider provider;
  const _AdjustmentForm({required this.provider});

  @override
  State<_AdjustmentForm> createState() => _AdjustmentFormState();
}

class _AdjustmentFormState extends State<_AdjustmentForm> {
  final _reasonController = TextEditingController();
  DateTime _date = DateTime.now();
  // Mặc định giống web: 08:00 - 17:30; bỏ trống giờ nào thì giữ nguyên giờ đó.
  TimeOfDay? _checkIn = const TimeOfDay(hour: 8, minute: 0);
  TimeOfDay? _checkOut = const TimeOfDay(hour: 17, minute: 30);
  bool _sending = false;
  String? _error;

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime.now().subtract(const Duration(days: 366)),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _pickTime(bool isIn) async {
    final picked = await showTimePicker(context: context, initialTime: (isIn ? _checkIn : _checkOut) ?? TimeOfDay.now());
    if (picked != null) setState(() => isIn ? _checkIn = picked : _checkOut = picked);
  }

  Future<void> _submit() async {
    if (_reasonController.text.trim().isEmpty) {
      setState(() => _error = 'Vui lòng nhập lý do điều chỉnh.');
      return;
    }
    if (_checkIn == null && _checkOut == null) {
      setState(() => _error = 'Hãy đề xuất ít nhất một giờ vào hoặc giờ ra.');
      return;
    }
    setState(() {
      _sending = true;
      _error = null;
    });
    final error = await widget.provider.submitAdjustment(
      date: _date,
      reason: _reasonController.text.trim(),
      checkIn: _checkIn,
      checkOut: _checkOut,
    );
    if (!mounted) return;
    if (error == null) {
      Navigator.pop(context, true);
    } else {
      setState(() {
        _sending = false;
        _error = error;
      });
    }
  }

  Widget _timeField(String label, TimeOfDay? value, bool isIn) {
    return Expanded(
      child: InkWell(
        onTap: () => _pickTime(isIn),
        child: InputDecorator(
          decoration: InputDecoration(
            labelText: label,
            border: const OutlineInputBorder(),
            suffixIcon: value == null
                ? null
                : IconButton(
                    icon: const Icon(Icons.close, size: 18),
                    onPressed: () => setState(() => isIn ? _checkIn = null : _checkOut = null),
                  ),
          ),
          child: Text(value == null ? 'Bỏ trống' : value.format(context)),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + MediaQuery.of(context).viewInsets.bottom),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Yêu cầu chỉnh sửa chấm công', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            InkWell(
              onTap: _pickDate,
              child: InputDecorator(
                decoration: const InputDecoration(labelText: 'Ngày cần chỉnh sửa *', border: OutlineInputBorder()),
                child: Text(formatDate(_date)),
              ),
            ),
            const SizedBox(height: 12),
            Row(children: [
              _timeField('Giờ vào đề xuất', _checkIn, true),
              const SizedBox(width: 12),
              _timeField('Giờ ra đề xuất', _checkOut, false),
            ]),
            const SizedBox(height: 4),
            Text(
              'Bỏ trống giờ vào nếu quên check-out, bỏ trống giờ ra nếu quên check-in.',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _reasonController,
              maxLines: 3,
              decoration: const InputDecoration(labelText: 'Lý do *', border: OutlineInputBorder()),
            ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(_error!, style: const TextStyle(color: Colors.red)),
              ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2A5CAA),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onPressed: _sending ? null : _submit,
                child: _sending
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('Gửi yêu cầu'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
