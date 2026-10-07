import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../core/network/api_client.dart';
import '../../../models/attendance_record.dart';
import '../../../models/leave_request.dart';
import '../../../services/attendance_service.dart';
import '../../attendance/widgets/attendance_status.dart';
import '../../auth/providers/auth_provider.dart';
import '../../leave/providers/leave_provider.dart';
import '../../profile/providers/profile_provider.dart';
import '../widgets/attendance_day_cell.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  DateTime _selectedDate = DateTime.now();
  DateTime _focusedMonth = DateTime.now();

  // Tuần bắt đầu từ thứ Hai, kết thúc Chủ nhật.
  final List<String> _weekDays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  // Chiều cao 1 hàng ngày: số ngày (30) + khoảng cách + 2 vạch trạng thái, thêm chút đệm.
  static const double _rowHeight = 52;

  // Lịch sử chấm công theo ngày (khoá yyyy-MM-dd).
  Map<String, AttendanceRecord> _records = {};
  bool _loadingRecords = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadRecords());
  }

  // Tải toàn bộ lịch sử chấm công để tô màu các ngày; đơn nghỉ lấy từ LeaveProvider (đã tải ở Dashboard).
  Future<void> _loadRecords() async {
    final employeeCode = context.read<AuthProvider>().session?.employeeCode;
    if (employeeCode == null) return;

    setState(() => _loadingRecords = true);
    try {
      final history = await AttendanceService(context.read<ApiClient>()).getHistory(employeeCode);
      if (!mounted) return;
      setState(() => _records = {for (final r in history) r.attendanceDate: r});
    } catch (_) {
      // Không tải được thì lịch chỉ còn ngày nghỉ phép và cuối tuần.
    } finally {
      if (mounted) setState(() => _loadingRecords = false);
    }
  }

  void _changeMonth(int offset) {
    setState(() {
      _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month + offset, 1);
    });
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
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF2A5CAA),
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
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
    }
  }

  static bool _sameDay(DateTime a, DateTime b) => a.year == b.year && a.month == b.month && a.day == b.day;

  static bool _isWeekend(DateTime d) => d.weekday == DateTime.saturday || d.weekday == DateTime.sunday;

  // Đơn nghỉ đã được duyệt có phủ ngày này không (so theo ngày, bỏ giờ).
  LeaveRequest? _approvedLeaveOn(DateTime date, List<LeaveRequest> requests) {
    final day = DateTime(date.year, date.month, date.day);
    for (final r in requests) {
      if (r.status != 'Approved' && r.status != 'Confirmed' && r.status != 'Completed') continue;
      final start = DateTime(r.startDate.year, r.startDate.month, r.startDate.day);
      final end = DateTime(r.endDate.year, r.endDate.month, r.endDate.day);
      if (!day.isBefore(start) && !day.isAfter(end)) return r;
    }
    return null;
  }

  // Ngày làm việc đã qua (không tính hôm nay), tính từ ngày vào làm trở đi.
  bool _isPastWorkday(DateTime date, DateTime? hireDate) {
    final today = DateTime.now();
    final startOfToday = DateTime(today.year, today.month, today.day);
    final beforeHire = hireDate != null && date.isBefore(DateTime(hireDate.year, hireDate.month, hireDate.day));
    return date.isBefore(startOfToday) && !beforeHire && !_loadingRecords;
  }

  AttendanceRecord? _recordOn(DateTime date) => _records[DateFormat('yyyy-MM-dd').format(date)];

  // Trạng thái của buổi đi làm (buổi còn lại khi có nghỉ nửa ngày có phép).
  DayPartStatus _workedHalf(DateTime date, DateTime? hireDate) {
    final record = _recordOn(date);
    if (record == null) return _isPastWorkday(date, hireDate) ? DayPartStatus.absent : DayPartStatus.none;

    switch (record.status) {
      case 'Present':
        return DayPartStatus.onTime;
      case 'Late':
        return DayPartStatus.late;
      case 'HalfDay':
        // Backend đánh dấu HalfDay khi duyệt nghỉ nửa ngày; có check-in thật thì buổi còn lại là đi làm.
        if (record.checkInTime != null) return DayPartStatus.onTime;
        return _isPastWorkday(date, hireDate) ? DayPartStatus.absent : DayPartStatus.none;
      case 'OnLeave':
        return DayPartStatus.off;
      default:
        return DayPartStatus.absent; // Absent, HalfDayAbsent
    }
  }

  // Thứ tự ưu tiên: nghỉ phép (cả ngày hoặc nửa ngày) -> bản ghi chấm công
  // -> ngày làm việc đã qua mà không có bản ghi (vắng không phép). Cuối tuần do ô ngày tự ẩn vạch.
  DayAttendance _attendanceOf(DateTime date, List<LeaveRequest> requests, DateTime? hireDate) {
    final leave = _approvedLeaveOn(date, requests);
    if (leave != null) {
      if (leave.session == 'Morning') return DayAttendance(DayPartStatus.off, _workedHalf(date, hireDate));
      if (leave.session == 'Afternoon') return DayAttendance(_workedHalf(date, hireDate), DayPartStatus.off);
      return const DayAttendance(DayPartStatus.off, DayPartStatus.off); // nghỉ cả ngày
    }

    final record = _recordOn(date);
    if (record == null) {
      final s = _isPastWorkday(date, hireDate) ? DayPartStatus.absent : DayPartStatus.none;
      return DayAttendance(s, s);
    }

    switch (record.status) {
      case 'Present':
        return const DayAttendance(DayPartStatus.onTime, DayPartStatus.onTime);
      case 'Late':
        return const DayAttendance(DayPartStatus.late, DayPartStatus.late);
      case 'OnLeave':
        return const DayAttendance(DayPartStatus.off, DayPartStatus.off);
      case 'HalfDayAbsent':
        // Vắng buổi sáng không phép, buổi chiều có đi làm.
        return const DayAttendance(DayPartStatus.absent, DayPartStatus.onTime);
      case 'HalfDay':
        // Nghỉ nửa ngày có phép nhưng không tìm thấy đơn để biết buổi nào: mặc định nghỉ sáng.
        return DayAttendance(DayPartStatus.off, _workedHalf(date, hireDate));
      default:
        return const DayAttendance(DayPartStatus.absent, DayPartStatus.absent); // Absent
    }
  }

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
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.black54)),
      ],
    );
  }

  static String _sessionText(String? session) {
    switch (session) {
      case 'Morning':
        return 'buổi sáng';
      case 'Afternoon':
        return 'buổi chiều';
      default:
        return 'cả ngày';
    }
  }

  // Nội dung chi tiết của ngày đang chọn.
  List<Widget> _detailRows(DateTime date, List<LeaveRequest> requests, DateTime? hireDate) {
    Widget row(IconData icon, Color color, String text) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            children: [
              Icon(icon, size: 18, color: color),
              const SizedBox(width: 12),
              Expanded(child: Text(text, style: const TextStyle(fontSize: 14, color: Colors.black87))),
            ],
          ),
        );

    final off = dayPartColor(DayPartStatus.off)!;
    if (_isWeekend(date)) {
      return [row(Icons.weekend, off, 'DAY-OFF (cuối tuần)')];
    }

    final rows = <Widget>[];
    final leave = _approvedLeaveOn(date, requests);
    if (leave != null) {
      rows.add(row(Icons.beach_access, off, 'Nghỉ phép ${_sessionText(leave.session)}: ${leave.leaveTypeName}'));
    }

    final record = _recordOn(date);
    if (record != null) {
      final att = _attendanceOf(date, requests, hireDate);
      final dot = dayPartColor(att.afternoon) ?? dayPartColor(att.morning) ?? Colors.grey;
      rows.add(row(Icons.circle, dot, attendanceLabel(record.status)));
      final timeFormat = DateFormat('HH:mm');
      if (record.checkInTime != null) {
        rows.add(row(Icons.login, Colors.blueGrey, 'Vào: ${timeFormat.format(record.checkInTime!)}'));
      }
      if (record.checkOutTime != null) {
        rows.add(row(Icons.logout, Colors.blueGrey, 'Ra: ${timeFormat.format(record.checkOutTime!)}'));
      }
      return rows;
    }

    if (leave == null) {
      if (_isPastWorkday(date, hireDate)) {
        rows.add(row(Icons.circle, dayPartColor(DayPartStatus.absent)!, 'Vắng mặt (không xin phép)'));
      } else {
        rows.add(row(Icons.circle_outlined, Colors.grey, 'Chưa có dữ liệu chấm công'));
      }
    }
    return rows;
  }

  @override
  Widget build(BuildContext context) {
    final requests = context.watch<LeaveProvider>().requests;
    final hireDate = context.watch<ProfileProvider>().employee?.hireDate;

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
                  const Text('Calendar', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                  IconButton(
                    icon: const Icon(Icons.calendar_month, color: Color(0xFF2A5CAA)),
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
                  IconButton(icon: const Icon(Icons.chevron_left, color: Color(0xFF2A5CAA)), onPressed: () => _changeMonth(-1)),
                  Text(
                    DateFormat('MMMM yyyy').format(_focusedMonth),
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black87),
                  ),
                  IconButton(icon: const Icon(Icons.chevron_right, color: Color(0xFF2A5CAA)), onPressed: () => _changeMonth(1)),
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
                  const SizedBox(height: 4),
                  const Text(
                    'Vạch dưới mỗi ngày: trái là buổi sáng, phải là buổi chiều (cùng trạng thái thì nối thành 1 vạch)',
                    style: TextStyle(fontSize: 11, color: Colors.black45),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),

            // 3. Thứ trong tuần (Mon -> Sun)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                children: _weekDays
                    .map((day) => Expanded(
                          child: Center(
                            child: Text(
                              day,
                              style: TextStyle(
                                color: day == 'Sun' ? Colors.red.shade300 : Colors.grey, // Chữ Sun màu đỏ nhạt
                                fontSize: 13,
                                fontWeight: day == 'Sun' ? FontWeight.bold : FontWeight.normal,
                              ),
                            ),
                          ),
                        ))
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
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 7,
                  mainAxisExtent: _rowHeight,
                ),
                itemBuilder: (context, index) {
                  if (index < firstDayOffset || index >= firstDayOffset + daysInMonth) {
                    return const SizedBox.shrink();
                  }

                  final currentDate = DateTime(_focusedMonth.year, _focusedMonth.month, index - firstDayOffset + 1);
                  return AttendanceDayCell(
                    day: currentDate,
                    attendance: _attendanceOf(currentDate, requests, hireDate),
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
                    DateFormat('dd/MM/yyyy (EEE)').format(_selectedDate),
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
                  ),
                  const SizedBox(height: 16),
                  ..._detailRows(_selectedDate, requests, hireDate),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
