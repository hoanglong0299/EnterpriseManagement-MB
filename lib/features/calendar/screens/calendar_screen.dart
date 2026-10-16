import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../core/network/api_client.dart';
import '../../../core/utils/vi_date.dart';
import '../../../models/attendance_hr.dart';
import '../../../services/hr_service.dart';
import '../../../shared/widgets/state_views.dart';
import '../../../shared/widgets/permission_gate.dart';
import '../../attendance/widgets/adjustment_form.dart';
import '../../auth/providers/auth_provider.dart';
import '../widgets/attendance_day_cell.dart';
import '../widgets/month_year_picker.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  DateTime _selectedDate = DateTime.now();
  DateTime _focusedMonth = DateTime.now();

  // Tuần bắt đầu từ thứ Hai, kết thúc Chủ nhật.
  final List<String> _weekDays = ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'];

  // Chiều cao 1 hàng ngày: số ngày (30) + khoảng cách + 2 vạch trạng thái, thêm chút đệm.
  static const double _rowHeight = 52;

  // Dữ liệu lịch hiệu lực từ backend, cache theo tháng (khoá yyyy-MM) và theo ngày (khoá yyyy-MM-dd).
  final Map<String, Map<String, AttendanceCalendarDay>> _monthCache = {};
  bool _loading = false;
  String? _error;

  static String _monthKey(DateTime m) => DateFormat('yyyy-MM').format(m);
  static String _dayKey(DateTime d) => DateFormat('yyyy-MM-dd').format(d);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadMonth(_focusedMonth, force: true));
  }

  // Tải lịch của một tháng; tháng đã có trong cache thì bỏ qua trừ khi force.
  Future<void> _loadMonth(DateTime month, {bool force = false}) async {
    final key = _monthKey(month);
    if (!force && _monthCache.containsKey(key)) return;
    final employeeCode = context.read<AuthProvider>().session?.employeeCode;
    if (employeeCode == null) return;

    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final from = DateTime(month.year, month.month, 1);
      final to = DateTime(month.year, month.month + 1, 0);
      final days = await HrService(context.read<ApiClient>()).getCalendar(employeeCode, from, to);
      if (!mounted) return;
      setState(() => _monthCache[key] = {for (final d in days) _dayKey(d.date): d});
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _changeMonth(int offset) {
    setState(() {
      _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month + offset, 1);
    });
    _loadMonth(_focusedMonth);
  }

  Future<void> _pickMonthYear() async {
    final picked = await showMonthYearPicker(context, _focusedMonth);
    if (picked == null || !mounted) return;
    setState(() {
      _focusedMonth = picked;
      // Giữ ngày đang chọn nếu còn nằm trong tháng mới, không thì chọn ngày 1 để phần chi tiết bên dưới khớp tháng.
      final lastDay = DateTime(picked.year, picked.month + 1, 0).day;
      _selectedDate = DateTime(picked.year, picked.month, _selectedDate.day.clamp(1, lastDay));
    });
    _loadMonth(_focusedMonth);
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(primary: Color(0xFF5A3FD8), onPrimary: Colors.white, onSurface: Colors.black),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _focusedMonth = DateTime(picked.year, picked.month, 1);
      });
      _loadMonth(_focusedMonth);
    }
  }

  // Gửi yêu cầu chỉnh sửa cho ngày đang chọn; thành công thì tải lại tháng.
  Future<void> _requestAdjustment() async {
    final ok = await showAdjustmentForm(context, initialDate: _selectedDate);
    if (ok == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đã gửi yêu cầu điều chỉnh chấm công')));
      _loadMonth(_focusedMonth, force: true);
    }
  }

  // Chỉ cho yêu cầu với ngày làm việc (không cuối tuần) và không ở tương lai.
  bool get _canRequestAdjustment {
    final today = DateTime.now();
    final d = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day);
    return d.weekday < DateTime.saturday && !d.isAfter(DateTime(today.year, today.month, today.day));
  }

  static bool _sameDay(DateTime a, DateTime b) => a.year == b.year && a.month == b.month && a.day == b.day;

  static bool _isWeekend(DateTime d) => d.weekday == DateTime.saturday || d.weekday == DateTime.sunday;

  AttendanceCalendarDay? _dayData(DateTime date) => _monthCache[_monthKey(date)]?[_dayKey(date)];

  // Ánh xạ trạng thái buổi của backend sang vạch màu.
  static DayPartStatus _part(String s) => switch (s) {
    'OnTime' => DayPartStatus.onTime,
    'Late' => DayPartStatus.late,
    'Absent' => DayPartStatus.absent,
    'OnLeave' => DayPartStatus.off,
    _ => DayPartStatus.none,
  };

  DayAttendance? _attendanceOf(DateTime date) {
    final d = _dayData(date);
    if (d == null) return null;
    return DayAttendance(_part(d.morning), _part(d.afternoon));
  }

  static String _partText(String s) => switch (s) {
    'OnTime' => 'Đúng giờ',
    'Late' => 'Đi muộn',
    'Absent' => 'Vắng mặt',
    'OnLeave' => 'Nghỉ phép',
    _ => 'Chưa có dữ liệu',
  };

  // Chú thích: vạch màu + nhãn.
  Widget _legendItem(DayPartStatus status, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 14,
          height: 4,
          decoration: BoxDecoration(color: dayPartColor(status), borderRadius: BorderRadius.circular(2)),
        ),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontSize: 14, color: Colors.black54)),
      ],
    );
  }

  Widget _detailRow(IconData icon, Color color, String text) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 12),
        Expanded(
          child: Text(text, style: const TextStyle(fontSize: 16, color: Colors.black87)),
        ),
      ],
    ),
  );

  // Một buổi: trạng thái + loại nghỉ phép / ghi chú HR / xác nhận đi làm lại theo nguồn.
  List<Widget> _sessionRows(String label, String status, String source, AttendanceCalendarDay d, String? note) {
    final color = dayPartColor(_part(status)) ?? Colors.grey;
    final rows = <Widget>[
      _detailRow(
        Icons.circle,
        color,
        '$label: ${_partText(status)}${status == 'OnLeave' && d.leaveTypeName != null ? ' (${d.leaveTypeName})' : ''}',
      ),
    ];
    if (source == 'Note' && note != null && note.isNotEmpty) {
      rows.add(_detailRow(Icons.sticky_note_2_outlined, Colors.blueGrey, 'Ghi chú của HR: $note'));
    } else if (source == 'ReturnConfirmed') {
      rows.add(_detailRow(Icons.verified_outlined, Colors.blueGrey, 'Đã được HR xác nhận (đi làm lại)'));
    }
    return rows;
  }

  // Nội dung chi tiết của ngày đang chọn, lấy từ dữ liệu backend.
  List<Widget> _detailRows(DateTime date) {
    final off = dayPartColor(DayPartStatus.off)!;
    if (_isWeekend(date)) return [_detailRow(Icons.weekend, off, 'NGÀY NGHỈ (cuối tuần)')];

    final d = _dayData(date);
    if (d == null) {
      return [_detailRow(Icons.circle_outlined, Colors.grey, _loading ? 'Đang tải...' : 'Chưa có dữ liệu chấm công')];
    }
    final timeFormat = DateFormat('HH:mm');
    return [
      ..._sessionRows('Buổi sáng', d.morning, d.morningSource, d, d.morningNote),
      ..._sessionRows('Buổi chiều', d.afternoon, d.afternoonSource, d, d.afternoonNote),
      if (d.checkInTime != null) _detailRow(Icons.login, Colors.blueGrey, 'Vào: ${timeFormat.format(d.checkInTime!.toLocal())}'),
      if (d.checkOutTime != null) _detailRow(Icons.logout, Colors.blueGrey, 'Ra: ${timeFormat.format(d.checkOutTime!.toLocal())}'),
    ];
  }

  @override
  Widget build(BuildContext context) {
    int daysInMonth = DateTime(_focusedMonth.year, _focusedMonth.month + 1, 0).day;
    // weekday: Thứ Hai = 1 ... Chủ nhật = 7, nên số ô trống đầu tháng (tuần bắt đầu thứ Hai) là weekday - 1.
    int firstDayOffset = DateTime(_focusedMonth.year, _focusedMonth.month, 1).weekday - 1;
    // Chỉ vẽ đủ số hàng cần thiết (4-6 hàng) thay vì cố định 6 hàng.
    int rowCount = ((firstDayOffset + daysInMonth) / 7).ceil();

    return Container(
      color: Colors.white,
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          children: [
            // 1. Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Lịch',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                  ),
                  IconButton(
                    icon: const Icon(Icons.calendar_month, color: Color(0xFF5A3FD8)),
                    onPressed: () => _selectDate(context),
                  ),
                ],
              ),
            ),

            // 2. Bộ chọn Tháng / Năm
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left, color: Color(0xFF5A3FD8)),
                    onPressed: () => _changeMonth(-1),
                  ),
                  // Bấm vào tháng/năm để chọn nhanh tháng, năm khác.
                  Flexible(
                    child: InkWell(
                      borderRadius: BorderRadius.circular(10),
                      onTap: _pickMonthYear,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Flexible(
                              child: Text(
                                viMonthYear(_focusedMonth),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.black87),
                              ),
                            ),
                            const Icon(Icons.arrow_drop_down, color: Color(0xFF5A3FD8)),
                          ],
                        ),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.chevron_right, color: Color(0xFF5A3FD8)),
                    onPressed: () => _changeMonth(1),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 6),

            // Chú thích vạch màu
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                children: [
                  Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 14,
                    runSpacing: 6,
                    children: [
                      _legendItem(DayPartStatus.onTime, 'Đúng giờ'),
                      _legendItem(DayPartStatus.late, 'Đi muộn'),
                      _legendItem(DayPartStatus.absent, 'Vắng'),
                      _legendItem(DayPartStatus.off, 'Nghỉ phép'),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),

            // 3. Thứ trong tuần (T2 -> CN)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                children: _weekDays
                    .map(
                      (day) => Expanded(
                        child: Center(
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              day,
                              style: TextStyle(
                                color: day == 'CN' ? Colors.red.shade300 : Colors.grey, // Chữ CN màu đỏ nhạt
                                fontSize: 15,
                                fontWeight: day == 'CN' ? FontWeight.bold : FontWeight.normal,
                              ),
                            ),
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
            const SizedBox(height: 6),

            // 4. Lưới Ngày trong tháng
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: rowCount * 7,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 7, mainAxisExtent: _rowHeight),
                itemBuilder: (context, index) {
                  if (index < firstDayOffset || index >= firstDayOffset + daysInMonth) {
                    return const SizedBox.shrink();
                  }

                  final currentDate = DateTime(_focusedMonth.year, _focusedMonth.month, index - firstDayOffset + 1);
                  return AttendanceDayCell(
                    day: currentDate,
                    attendance: _attendanceOf(currentDate),
                    isToday: _sameDay(DateTime.now(), currentDate),
                    isSelected: _sameDay(_selectedDate, currentDate),
                    isWeekend: _isWeekend(currentDate),
                    onTap: () => setState(() => _selectedDate = currentDate),
                  );
                },
              ),
            ),
            const SizedBox(height: 8),

            // 5. Chi tiết của ngày đang chọn
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20.0),
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: Colors.black12, width: 1)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${DateFormat('dd/MM/yyyy').format(_selectedDate)} (${viWeekdayShort(_selectedDate.weekday)})',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
                  ),
                  const SizedBox(height: 16),
                  if (_error != null)
                    ErrorView(message: _error!, onRetry: () => _loadMonth(_focusedMonth, force: true))
                  else
                    ..._detailRows(_selectedDate),
                  if (_canRequestAdjustment)
                    PermissionGate(
                      code: 'attendance.adjustment.self',
                      child: Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: OutlinedButton.icon(
                          onPressed: _requestAdjustment,
                          icon: const Icon(Icons.edit_calendar_outlined),
                          label: const Text('Yêu cầu chỉnh sửa'),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
