import 'package:enterprise_management/models/attendance_hr.dart';
import 'package:enterprise_management/models/overtime.dart';
import 'package:enterprise_management/models/timesheet.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Làm thêm giờ', () {
    test('đọc đơn OT từ backend và dựng nhãn', () {
      final r = OvertimeRequest.fromJson({
        'id': 7,
        'employeeCode': 'ABC',
        'employeeName': 'Hoàng Thị Lan',
        'date': '2026-10-22',
        'startTime': '17:00',
        'endTime': '19:30',
        'minutes': 150,
        'reason': 'Chạy báo cáo',
        'status': 'Pending',
        'createdAt': '2026-10-19T12:14:35.366366',
      });
      expect(r.dateLabel, '22/10/2026');
      expect(r.timeLabel, '17:00 - 19:30');
      expect(r.durationLabel, '2 giờ 30 phút');
      expect(r.statusLabel, 'Chờ duyệt');
    });

    test('nhãn thời lượng', () {
      expect(overtimeDurationLabel(30), '30 phút');
      expect(overtimeDurationLabel(120), '2 giờ');
      expect(overtimeDurationLabel(90), '1 giờ 30 phút');
    });

    test('hạn mức: tỷ lệ đã dùng bị chặn ở 100%', () {
      final q = OvertimeQuota.fromJson({
        'year': 2026,
        'month': 10,
        'monthUsedMinutes': 3000,
        'monthLimitMinutes': 2400,
        'yearUsedMinutes': 600,
        'yearLimitMinutes': 12000,
      });
      expect(q.monthRatio, 1.0);
      expect(q.yearRatio, closeTo(0.05, 1e-9));
    });
  });

  group('Bảng công tháng', () {
    test('đọc bảng công và trạng thái chốt', () {
      final t = Timesheet.fromJson({
        'year': 2026,
        'month': 9,
        'standardDays': 22,
        'isClosed': true,
        'closedAt': '2026-10-01T09:00:00',
        'closedByName': 'Lý Văn Sơn',
        'rows': [
          {
            'employeeCode': 'A1',
            'employeeName': 'An',
            'departmentName': 'Kinh doanh',
            'workedDays': 20.5,
            'leaveDays': 1,
            'absentDays': 0.5,
            'lateSessions': 2,
            'overtimeHours': 3.5,
          },
        ],
      });
      expect(t.isClosed, true);
      expect(t.rows.single.workedDays, 20.5);
      expect(t.rows.single.overtimeHours, 3.5);
    });

    test('số ngày công hiển thị dấu phẩy kiểu Việt Nam', () {
      expect(dayCountLabel(18.5), '18,5');
      expect(dayCountLabel(20.0), '20');
    });
  });

  test('lịch: ngày lễ và OT được đọc từ dữ liệu ngày', () {
    final day = AttendanceCalendarDay.fromJson({
      'date': '2026-09-02',
      'isWeekend': false,
      'isHoliday': true,
      'holidayName': 'Quốc khánh',
      'overtimeMinutes': 120,
      'morning': 'None',
      'afternoon': 'None',
    });
    expect(day.isHoliday, true);
    expect(day.holidayName, 'Quốc khánh');
    expect(day.overtimeMinutes, 120);

    final plain = AttendanceCalendarDay.fromJson({'date': '2026-09-03', 'isWeekend': false});
    expect(plain.isHoliday, false);
    expect(plain.overtimeMinutes, 0);
  });
}
