import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../../models/leave_balance.dart';
import '../../../models/leave_request.dart';
import '../../../models/leave_type.dart';
import '../../../shared/widgets/confirm_dialog.dart';
import '../../../shared/widgets/permission_gate.dart';
import '../../../shared/widgets/state_views.dart';
import '../../../shared/widgets/status_chip.dart';
import '../providers/leave_provider.dart';
import '../widgets/leave_ui.dart';

String _num(double value) {
  return value == value.roundToDouble() ? value.toInt().toString() : value.toString().replaceAll('.', ',');
}

// ==========================================
// 1. MÀN HÌNH XIN NGHỈ PHÉP (route /employee/leave)
// Giống trang "Xin nghỉ phép" bên web: số dư, danh sách đơn, tạo/hủy đơn; thêm lịch tháng và bộ lọc cho điện thoại.
// ==========================================
class LeaveRecordScreen extends StatefulWidget {
  const LeaveRecordScreen({super.key});

  @override
  State<LeaveRecordScreen> createState() => _LeaveRecordScreenState();
}

class _LeaveRecordScreenState extends State<LeaveRecordScreen> {
  String? _statusFilter; // null = tất cả
  String? _typeFilter; // null = tất cả loại

  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<LeaveProvider>().load();
    });
  }

  void _navigateToApplyScreen() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const LeaveApplicationScreen()),
    );

    // Form trả về true khi đơn đã được gửi thành công; danh sách tự cập nhật qua LeaveProvider.
    if (result == true && mounted) {
      showMessage(context, 'Đơn nghỉ phép đã được gửi.');
    }
  }

  Future<void> _cancelRequest(LeaveRequest r) async {
    final confirmed = await confirmDialog(
      context,
      title: 'Hủy đơn nghỉ phép',
      message: 'Bạn có chắc muốn hủy đơn ${r.leaveTypeName} (${r.dateLabel}) không?',
      confirmText: 'Hủy đơn',
      danger: true,
    );
    if (!confirmed || !mounted) return;

    final provider = context.read<LeaveProvider>();
    final success = await provider.cancel(r.id);
    if (!mounted) return;
    showMessage(
      context,
      success ? 'Đã hủy đơn nghỉ phép.' : (provider.errorMessage ?? 'Không thể hủy đơn.'),
      error: !success,
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<LeaveProvider>();

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F7FA),
        appBar: AppBar(
          title: const Text('Xin nghỉ phép'),
          backgroundColor: const Color(0xFF2A5CAA),
          foregroundColor: Colors.white,
          bottom: const TabBar(
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            indicatorColor: Colors.white,
            tabs: [Tab(text: 'Đơn nghỉ'), Tab(text: 'Số dư'), Tab(text: 'Lịch')],
          ),
        ),
        floatingActionButton: PermissionGate(
          code: 'leave.request.self',
          child: FloatingActionButton.extended(
            onPressed: _navigateToApplyScreen,
            backgroundColor: const Color(0xFF2A5CAA),
            foregroundColor: Colors.white,
            icon: const Icon(Icons.add),
            label: const Text('Tạo đơn'),
          ),
        ),
        body: _buildBody(provider),
      ),
    );
  }

  Widget _buildBody(LeaveProvider provider) {
    final noData = provider.requests.isEmpty && provider.balances.isEmpty;
    if (provider.isLoading && noData) return const LoadingView();
    if (provider.errorMessage != null && noData) {
      return ErrorView(message: provider.errorMessage!, onRetry: provider.load);
    }

    return Column(
      children: [
        _buildMetrics(provider),
        Expanded(
          child: TabBarView(
            children: [
              _buildRequestsTab(provider),
              _buildBalancesTab(provider),
              _buildCalendarTab(provider),
            ],
          ),
        ),
      ],
    );
  }

  // 3 ô tóm tắt như MetricRail bên web: ngày phép còn lại, nghỉ ngắn tháng này, đơn chờ duyệt.
  Widget _buildMetrics(LeaveProvider provider) {
    final days = provider.balances.where((b) => b.unit == 'Days').fold<double>(0, (sum, b) => sum + b.remainingTime);
    final shorts = provider.balances.where((b) => b.unit == 'Hours').toList();
    final pending = provider.requests.where((r) => r.isPending).length;

    Widget tile(String label, String value, Color color) => Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10)),
            child: Column(
              children: [
                Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color)),
                const SizedBox(height: 2),
                Text(label, textAlign: TextAlign.center, style: const TextStyle(fontSize: 11, color: Colors.grey)),
              ],
            ),
          ),
        );

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
      child: Row(
        children: [
          tile('Ngày phép còn lại', '${_num(days)} ngày', const Color(0xFF2A5CAA)),
          const SizedBox(width: 8),
          tile(
            'Nghỉ ngắn tháng này',
            shorts.isEmpty ? '--' : '${_num(shorts.first.remainingTime)} giờ',
            const Color(0xFF2A5CAA),
          ),
          const SizedBox(width: 8),
          tile('Đang chờ duyệt', '$pending', pending > 0 ? StatusChip.warning : StatusChip.success),
        ],
      ),
    );
  }

  // ---------- Tab 1: danh sách đơn ----------
  Widget _buildRequestsTab(LeaveProvider provider) {
    final all = provider.requests;
    final filtered = all.where((r) {
      if (_statusFilter != null && r.status != _statusFilter) return false;
      if (_typeFilter != null && r.leaveTypeCode != _typeFilter) return false;
      return true;
    }).toList();

    return Column(
      children: [
        const SizedBox(height: 8),
        LeaveStatusFilterBar(selected: _statusFilter, onChanged: (v) => setState(() => _statusFilter = v)),
        if (provider.types.length > 1)
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 4, 12, 0),
            child: DropdownButtonFormField<String?>(
              value: _typeFilter,
              isDense: true,
              decoration: const InputDecoration(
                labelText: 'Loại nghỉ',
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              items: [
                const DropdownMenuItem<String?>(value: null, child: Text('Tất cả loại nghỉ')),
                for (final t in provider.types)
                  DropdownMenuItem<String?>(value: t.leaveTypeCode, child: Text(t.leaveTypeName)),
              ],
              onChanged: (v) => setState(() => _typeFilter = v),
            ),
          ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: provider.load,
            child: filtered.isEmpty
                ? ListView(children: [
                    const SizedBox(height: 80),
                    EmptyView(
                      message: all.isEmpty
                          ? 'Chưa có đơn nghỉ. Tạo đơn đầu tiên để bắt đầu quy trình duyệt.'
                          : 'Không có đơn phù hợp bộ lọc.',
                      icon: Icons.event_busy,
                    ),
                  ])
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(12, 8, 12, 88),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) => _buildRequestCard(filtered[index]),
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildRequestCard(LeaveRequest r) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => showLeaveDetail(context, r),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      r.leaveTypeName,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF2A5CAA)),
                    ),
                  ),
                  LeaveStatusChip(r),
                ],
              ),
              const Divider(),
              Text('Ngày nghỉ: ${r.dateLabel}'),
              Text('Thời gian: ${r.timeLabel} · ${r.durationLabel}'),
              if ((r.reason ?? '').isNotEmpty)
                Text('Lý do: ${r.reason}', style: const TextStyle(color: Colors.black54)),
              if ((r.rejectionReason ?? '').isNotEmpty)
                Text('Lý do từ chối: ${r.rejectionReason}', style: const TextStyle(color: Colors.black54)),
              // Đơn đang chờ duyệt thì nhân viên được hủy (giống bản web)
              if (r.isPending)
                PermissionGate(
                  code: 'leave.request.self',
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () => _cancelRequest(r),
                      child: const Text('HỦY ĐƠN', style: TextStyle(color: Colors.red)),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  // ---------- Tab 2: số dư theo từng loại ----------
  Widget _buildBalancesTab(LeaveProvider provider) {
    final balances = provider.balances;
    return RefreshIndicator(
      onRefresh: provider.load,
      child: balances.isEmpty
          ? ListView(children: const [
              SizedBox(height: 80),
              EmptyView(
                message: 'Chưa có số dư. Số dư nghỉ phép sẽ hiển thị sau khi Admin cấu hình.',
                icon: Icons.account_balance_wallet_outlined,
              ),
            ])
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: balances.length,
              itemBuilder: (context, index) => _buildBalanceCard(balances[index]),
            ),
    );
  }

  Widget _buildBalanceCard(LeaveBalance b) {
    final unit = b.unit == 'Hours' ? 'giờ' : 'ngày';
    final ratio = b.allocatedTime <= 0 ? 0.0 : (b.usedTime / b.allocatedTime).clamp(0.0, 1.0);
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(b.leaveTypeName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ),
                Text(
                  '${_num(b.remainingTime)} / ${_num(b.allocatedTime)} $unit',
                  style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF2A5CAA)),
                ),
              ],
            ),
            const SizedBox(height: 2),
            Text(b.periodLabel, style: const TextStyle(color: Colors.grey, fontSize: 12)),
            const SizedBox(height: 10),
            LinearProgressIndicator(value: ratio, minHeight: 6, borderRadius: BorderRadius.circular(3)),
            const SizedBox(height: 6),
            Text('Đã dùng ${_num(b.usedTime)} $unit', style: const TextStyle(fontSize: 12, color: Colors.black54)),
          ],
        ),
      ),
    );
  }

  // ---------- Tab 3: lịch tháng các ngày nghỉ ----------
  // Chỉ đánh dấu đơn Chờ duyệt / Đã duyệt (đơn bị từ chối, đã hủy không chiếm ngày).
  List<LeaveRequest> _eventsFor(LeaveProvider provider, DateTime day) {
    final d = DateTime(day.year, day.month, day.day);
    return provider.requests.where((r) {
      if (r.status != 'Pending' && r.status != 'Approved') return false;
      final start = DateTime(r.startDate.year, r.startDate.month, r.startDate.day);
      final end = DateTime(r.endDate.year, r.endDate.month, r.endDate.day);
      return !d.isBefore(start) && !d.isAfter(end);
    }).toList();
  }

  Widget _buildCalendarTab(LeaveProvider provider) {
    final selectedEvents = _eventsFor(provider, _selectedDay);
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        Card(
          child: TableCalendar<LeaveRequest>(
            firstDay: DateTime(2020),
            lastDay: DateTime(2100),
            focusedDay: _focusedDay,
            startingDayOfWeek: StartingDayOfWeek.monday,
            availableCalendarFormats: const {CalendarFormat.month: 'Tháng'},
            selectedDayPredicate: (day) => isSameDay(day, _selectedDay),
            eventLoader: (day) => _eventsFor(provider, day),
            onDaySelected: (selected, focused) => setState(() {
              _selectedDay = selected;
              _focusedDay = focused;
            }),
            onPageChanged: (focused) => _focusedDay = focused,
            calendarStyle: const CalendarStyle(
              selectedDecoration: BoxDecoration(color: Color(0xFF2A5CAA), shape: BoxShape.circle),
              todayDecoration: BoxDecoration(color: Color(0x662A5CAA), shape: BoxShape.circle),
              markerDecoration: BoxDecoration(color: StatusChip.warning, shape: BoxShape.circle),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Ngày ${DateFormat('dd/MM/yyyy').format(_selectedDay)}',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 6),
        if (selectedEvents.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Text('Không có đơn nghỉ trong ngày này.', style: TextStyle(color: Colors.grey)),
          )
        else
          for (final r in selectedEvents)
            Card(
              child: ListTile(
                title: Text(r.leaveTypeName),
                subtitle: Text('${r.dateLabel} · ${r.timeLabel}'),
                trailing: LeaveStatusChip(r),
                onTap: () => showLeaveDetail(context, r),
              ),
            ),
      ],
    );
  }
}

// ==========================================
// 2. MÀN HÌNH ĐIỀN FORM TẠO ĐƠN NGHỈ (giống dialog "Tạo đơn nghỉ phép" bên web)
// ==========================================
class LeaveApplicationScreen extends StatefulWidget {
  const LeaveApplicationScreen({super.key});

  @override
  State<LeaveApplicationScreen> createState() => _LeaveApplicationScreenState();
}

class _LeaveApplicationScreenState extends State<LeaveApplicationScreen> {
  // Khung giờ nghỉ ngắn cố định 30 phút, khớp ShortLeaveSlotStarts ở backend (sáng 8-12h, chiều 13-17h).
  static const _shortSlots = [
    '08:00', '08:30', '09:00', '09:30', '10:00', '10:30', '11:00', '11:30',
    '13:00', '13:30', '14:00', '14:30', '15:00', '15:30', '16:00', '16:30',
  ];

  static const _sessionLabels = {
    'Morning': 'Buổi sáng (08:00-12:00)',
    'Afternoon': 'Buổi chiều (13:00-17:00)',
    'FullDay': 'Cả ngày',
  };

  final _reasonController = TextEditingController();
  final _dateFormat = DateFormat('dd/MM/yyyy');

  LeaveType? _type;
  late DateTime _startDate;
  late DateTime _endDate;
  String _session = 'FullDay';
  String _slot = _shortSlots.first;
  bool _submitting = false;

  // Nghỉ có phép phải xin trước ít nhất 1 ngày làm việc: trước/đúng 17h thì sớm nhất là ngày mai, sau 17h là ngày kia.
  // Khớp ResolveRequestedTime ở backend.
  late final DateTime _minAnnualDate;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    final minutes = now.hour * 60 + now.minute;
    final ahead = minutes <= 17 * 60 ? 1 : 2;
    _minAnnualDate = DateTime(now.year, now.month, now.day + ahead);
    _startDate = DateTime(now.year, now.month, now.day);
    _endDate = _startDate;

    // Provider đã tải loại nghỉ ở màn trước; nếu chưa có thì tải rồi chọn loại đầu tiên.
    final provider = context.read<LeaveProvider>();
    if (provider.types.isEmpty) {
      provider.load().then((_) {
        if (mounted) setState(() => _selectType(_activeTypes(provider).firstOrNull));
      });
    } else {
      _selectType(_activeTypes(provider).firstOrNull);
    }
  }

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  List<LeaveType> _activeTypes(LeaveProvider provider) => provider.types.where((t) => t.isActive).toList();

  bool get _isAnnual => _type?.leaveTypeCode == 'ANNUAL';
  bool get _isShort => _type?.isShortLeave ?? false;
  bool get _isMultiDay => !_isSameDate(_startDate, _endDate);

  bool _isSameDate(DateTime a, DateTime b) => a.year == b.year && a.month == b.month && a.day == b.day;

  void _selectType(LeaveType? type) {
    _type = type;
    // Nghỉ có phép: đẩy ngày về ngày sớm nhất được phép.
    if (_isAnnual && _startDate.isBefore(_minAnnualDate)) {
      _startDate = _minAnnualDate;
      _endDate = _minAnnualDate;
    }
  }

  String _slotLabel(String start) {
    final parts = start.split(':').map(int.parse).toList();
    final end = parts[0] * 60 + parts[1] + 30;
    final endText = '${(end ~/ 60).toString().padLeft(2, '0')}:${(end % 60).toString().padLeft(2, '0')}';
    return '$start - $endText';
  }

  Future<void> _pickStart() async {
    final first = _isAnnual ? _minAnnualDate : DateTime.now().subtract(const Duration(days: 365));
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate.isBefore(first) ? first : _startDate,
      firstDate: first,
      lastDate: DateTime(2100),
    );
    if (picked == null) return;
    setState(() {
      _startDate = picked;
      if (_endDate.isBefore(picked)) _endDate = picked;
    });
  }

  Future<void> _pickEnd() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _endDate.isBefore(_startDate) ? _startDate : _endDate,
      firstDate: _startDate,
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => _endDate = picked);
  }

  Future<void> _submit() async {
    final type = _type;
    final reason = _reasonController.text.trim();
    if (type == null) return showMessage(context, 'Vui lòng chọn loại nghỉ.', error: true);
    if (_isAnnual && _startDate.isBefore(_minAnnualDate)) {
      return showMessage(
        context,
        'Nghỉ có phép phải xin trước ít nhất 1 ngày. Ngày sớm nhất có thể xin: ${_dateFormat.format(_minAnnualDate)}.',
        error: true,
      );
    }
    if (reason.isEmpty) return showMessage(context, 'Vui lòng nhập lý do xin nghỉ.', error: true);
    if (_submitting) return;

    setState(() => _submitting = true);
    final provider = context.read<LeaveProvider>();
    final bool success;
    if (_isShort) {
      final today = DateTime.now();
      final parts = _slot.split(':').map(int.parse).toList();
      final start = DateTime(today.year, today.month, today.day, parts[0], parts[1]);
      success = await provider.submitShortLeave(
        leaveTypeCode: type.leaveTypeCode,
        start: start,
        end: start.add(const Duration(minutes: 30)),
        reason: reason,
      );
    } else {
      success = await provider.submitLeave(
        leaveTypeCode: type.leaveTypeCode,
        startDate: _startDate,
        endDate: _endDate,
        session: _isMultiDay ? 'FullDay' : _session,
        reason: reason,
      );
    }
    if (!mounted) return;
    setState(() => _submitting = false);

    if (success) {
      Navigator.pop(context, true);
    } else {
      showMessage(context, provider.errorMessage ?? 'Đăng ký nghỉ thất bại', error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<LeaveProvider>();
    final types = _activeTypes(provider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tạo đơn nghỉ phép'),
        backgroundColor: const Color(0xFF2A5CAA),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _label('Loại nghỉ'),
            DropdownButtonFormField<String>(
              value: _type?.leaveTypeCode,
              isExpanded: true,
              decoration: const InputDecoration(border: OutlineInputBorder()),
              items: [
                for (final t in types) DropdownMenuItem(value: t.leaveTypeCode, child: Text(t.leaveTypeName)),
              ],
              onChanged: (code) => setState(() => _selectType(types.firstWhere((t) => t.leaveTypeCode == code))),
            ),
            if (types.isEmpty)
              const Padding(
                padding: EdgeInsets.only(top: 6),
                child: Text('Chưa có loại nghỉ nào được cấu hình.', style: TextStyle(color: Colors.red, fontSize: 12)),
              ),
            if ((_type?.description ?? '').isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(_type!.description!, style: const TextStyle(color: Colors.grey, fontSize: 12)),
              ),
            const SizedBox(height: 20),
            if (_isShort) ...[
              _label('Khung giờ nghỉ (hôm nay)'),
              DropdownButtonFormField<String>(
                value: _slot,
                decoration: const InputDecoration(border: OutlineInputBorder()),
                items: [for (final s in _shortSlots) DropdownMenuItem(value: s, child: Text(_slotLabel(s)))],
                onChanged: (v) => setState(() => _slot = v ?? _shortSlots.first),
              ),
            ] else ...[
              Row(
                children: [
                  Expanded(child: _dateField('Từ ngày', _startDate, _pickStart)),
                  const SizedBox(width: 12),
                  Expanded(child: _dateField('Đến ngày', _endDate, _pickEnd)),
                ],
              ),
              if (_isAnnual)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    'Nghỉ có phép phải xin trước ít nhất 1 ngày làm việc (sớm nhất ${_dateFormat.format(_minAnnualDate)}).',
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                ),
              const SizedBox(height: 20),
              _label('Buổi nghỉ'),
              DropdownButtonFormField<String>(
                value: _isMultiDay ? 'FullDay' : _session,
                isExpanded: true,
                decoration: const InputDecoration(border: OutlineInputBorder()),
                items: [
                  for (final e in _sessionLabels.entries) DropdownMenuItem(value: e.key, child: Text(e.value)),
                ],
                // Nghỉ nhiều ngày chỉ được chọn Cả ngày.
                onChanged: _isMultiDay ? null : (v) => setState(() => _session = v ?? 'FullDay'),
              ),
              if (_isMultiDay)
                const Padding(
                  padding: EdgeInsets.only(top: 6),
                  child: Text('Nghỉ nhiều ngày chỉ có thể chọn Cả ngày.', style: TextStyle(color: Colors.red, fontSize: 12)),
                ),
            ],
            const SizedBox(height: 20),
            _label('Lý do'),
            TextField(
              controller: _reasonController,
              maxLines: 3,
              decoration: const InputDecoration(border: OutlineInputBorder(), hintText: 'Nhập lý do chi tiết...'),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2A5CAA), foregroundColor: Colors.white),
                onPressed: _submitting ? null : _submit,
                child: _submitting
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('GỬI ĐƠN', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _label(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(text, style: const TextStyle(fontWeight: FontWeight.bold)),
      );

  Widget _dateField(String label, DateTime value, VoidCallback onTap) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label(label),
        InkWell(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
            decoration: BoxDecoration(border: Border.all(color: Colors.grey), borderRadius: BorderRadius.circular(4)),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(_dateFormat.format(value)),
                const Icon(Icons.calendar_today, size: 18, color: Colors.grey),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
