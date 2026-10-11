import 'package:flutter/material.dart';

/// Trạng thái của 1 buổi (sáng hoặc chiều). [off] là nghỉ có phép (xám), [none] là chưa có gì để hiển thị.
enum DayPartStatus { onTime, late, absent, off, none }

class DayAttendance {
  final DayPartStatus morning;
  final DayPartStatus afternoon;

  const DayAttendance(this.morning, this.afternoon);
}

Color? dayPartColor(DayPartStatus s) => switch (s) {
      DayPartStatus.onTime => const Color(0xFF639922),
      DayPartStatus.late => const Color(0xFFEF9F27),
      DayPartStatus.absent => const Color(0xFFE24B4A),
      DayPartStatus.off => const Color(0xFF9E9E9E),
      DayPartStatus.none => null,
    };

/// Ô 1 ngày: số ngày + 2 vạch nhỏ bên dưới (trái = sáng, phải = chiều); cùng trạng thái thì nối thành 1 vạch.
/// Hôm nay có vòng viền; ngày đang chọn có nền xanh nhạt; cuối tuần chữ xám và không có vạch.
class AttendanceDayCell extends StatelessWidget {
  static const Color accent = Color(0xFF2A5CAA);
  static const double _barWidth = 10;
  static const double _barGap = 3;

  final DateTime day;
  final DayAttendance? attendance;
  final bool isToday;
  final bool isSelected;
  final bool isWeekend;
  final VoidCallback? onTap;

  const AttendanceDayCell({
    super.key,
    required this.day,
    this.attendance,
    this.isToday = false,
    this.isSelected = false,
    this.isWeekend = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final textColor = isSelected
        ? accent
        : isWeekend
            ? Colors.grey
            : Colors.black87;

    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 30,
            height: 30,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isSelected ? accent.withValues(alpha: 0.12) : null,
              border: isToday ? Border.all(color: accent, width: 1.5) : null,
            ),
            child: Text(
              '${day.day}',
              style: TextStyle(
                fontSize: 16,
                fontWeight: (isToday || isSelected) ? FontWeight.w600 : FontWeight.w400,
                color: textColor,
              ),
            ),
          ),
          const SizedBox(height: 5),
          SizedBox(
            height: 4,
            child: attendance == null || isWeekend
                ? null
                : attendance!.morning == attendance!.afternoon
                    // Sáng và chiều cùng trạng thái thì nối 2 vạch thành 1 vạch dài (10 + 3 + 10).
                    ? Center(child: _bar(attendance!.morning, width: _barWidth * 2 + _barGap))
                    : Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _bar(attendance!.morning),
                          const SizedBox(width: _barGap),
                          _bar(attendance!.afternoon),
                        ],
                      ),
          ),
        ],
      ),
    );
  }

  Widget _bar(DayPartStatus s, {double width = _barWidth}) => Container(
        width: width,
        height: 4,
        decoration: BoxDecoration(
          color: dayPartColor(s) ?? Colors.transparent,
          borderRadius: BorderRadius.circular(2),
        ),
      );
}
