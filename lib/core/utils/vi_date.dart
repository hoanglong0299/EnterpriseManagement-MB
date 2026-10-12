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
