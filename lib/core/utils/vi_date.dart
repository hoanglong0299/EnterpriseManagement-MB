// Hàm hỗ trợ hiển thị ngày giờ bằng tiếng Việt (không phụ thuộc dữ liệu locale của intl).

const List<String> _thuNgan = ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'];
const List<String> _thuDay = ['Thứ Hai', 'Thứ Ba', 'Thứ Tư', 'Thứ Năm', 'Thứ Sáu', 'Thứ Bảy', 'Chủ nhật'];

/// Thứ viết tắt: T2..T7, CN. [weekday] theo DateTime (1 = thứ Hai ... 7 = Chủ nhật).
String viWeekdayShort(int weekday) => _thuNgan[(weekday - 1) % 7];

/// Thứ đầy đủ: Thứ Hai ... Chủ nhật.
String viWeekdayFull(int weekday) => _thuDay[(weekday - 1) % 7];

/// "Tháng 10, 2026".
String viMonthYear(DateTime d) => 'Tháng ${d.month}, ${d.year}';

/// "12 tháng 10, 2026".
String viLongDate(DateTime d) => '${d.day.toString().padLeft(2, '0')} tháng ${d.month}, ${d.year}';

/// Thời gian tương đối: "Vừa xong", "5 phút trước", "2 giờ trước", "Hôm qua", "3 ngày trước", hoặc dd/MM/yyyy.
String viRelativeTime(DateTime time, {DateTime? now}) {
  final current = now ?? DateTime.now();
  final t = time.isUtc ? time.toLocal() : time;
  final diff = current.difference(t);
  if (diff.isNegative || diff.inMinutes < 1) return 'Vừa xong';
  if (diff.inMinutes < 60) return '${diff.inMinutes} phút trước';
  final today = DateTime(current.year, current.month, current.day);
  final days = today.difference(DateTime(t.year, t.month, t.day)).inDays;
  if (days == 0) return '${diff.inHours} giờ trước';
  if (days == 1) return 'Hôm qua';
  if (days < 7) return '$days ngày trước';
  return '${t.day.toString().padLeft(2, '0')}/${t.month.toString().padLeft(2, '0')}/${t.year}';
}
