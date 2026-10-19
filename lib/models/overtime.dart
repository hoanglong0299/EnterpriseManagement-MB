import 'package:intl/intl.dart';

// Đơn xin làm thêm giờ (OvertimeRequestDto của backend).
class OvertimeRequest {
  final int id;
  final String employeeCode;
  final String employeeName;
  final DateTime date;
  final String startTime; // "HH:mm"
  final String endTime;
  final int minutes;
  final String reason;
  final String status; // Pending | Approved | Rejected | Cancelled
  final String? approverName;
  final DateTime? approvedAt;
  final String? rejectionReason;
  final DateTime createdAt;

  OvertimeRequest({
    required this.id,
    required this.employeeCode,
    required this.employeeName,
    required this.date,
    required this.startTime,
    required this.endTime,
    required this.minutes,
    required this.reason,
    required this.status,
    this.approverName,
    this.approvedAt,
    this.rejectionReason,
    required this.createdAt,
  });

  factory OvertimeRequest.fromJson(Map<String, dynamic> json) {
    return OvertimeRequest(
      id: (json['id'] as num).toInt(),
      employeeCode: json['employeeCode'] as String? ?? '',
      employeeName: json['employeeName'] as String? ?? '',
      date: DateTime.parse(json['date'] as String),
      startTime: json['startTime'] as String? ?? '',
      endTime: json['endTime'] as String? ?? '',
      minutes: (json['minutes'] as num?)?.toInt() ?? 0,
      reason: json['reason'] as String? ?? '',
      status: json['status'] as String? ?? 'Pending',
      approverName: json['approverName'] as String?,
      approvedAt: json['approvedAt'] == null ? null : DateTime.parse(json['approvedAt'] as String),
      rejectionReason: json['rejectionReason'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  String get statusLabel => overtimeStatusLabels[status] ?? status;
  String get dateLabel => DateFormat('dd/MM/yyyy').format(date);
  String get timeLabel => '$startTime - $endTime';
  String get durationLabel => overtimeDurationLabel(minutes);
}

const Map<String, String> overtimeStatusLabels = {
  'Pending': 'Chờ duyệt',
  'Approved': 'Đã duyệt',
  'Rejected': 'Từ chối',
  'Cancelled': 'Đã hủy',
};

// 90 -> "1 giờ 30 phút", 120 -> "2 giờ", 30 -> "30 phút".
String overtimeDurationLabel(int minutes) {
  final h = minutes ~/ 60;
  final m = minutes % 60;
  if (h == 0) return '$m phút';
  return m == 0 ? '$h giờ' : '$h giờ $m phút';
}

// Hạn mức làm thêm giờ theo luật (tháng/năm) và phần đã dùng hoặc đang chờ duyệt.
class OvertimeQuota {
  final int year;
  final int month;
  final int monthUsedMinutes;
  final int monthLimitMinutes;
  final int yearUsedMinutes;
  final int yearLimitMinutes;

  const OvertimeQuota({
    required this.year,
    required this.month,
    required this.monthUsedMinutes,
    required this.monthLimitMinutes,
    required this.yearUsedMinutes,
    required this.yearLimitMinutes,
  });

  factory OvertimeQuota.fromJson(Map<String, dynamic> json) {
    int n(String key) => (json[key] as num?)?.toInt() ?? 0;
    return OvertimeQuota(
      year: n('year'),
      month: n('month'),
      monthUsedMinutes: n('monthUsedMinutes'),
      monthLimitMinutes: n('monthLimitMinutes'),
      yearUsedMinutes: n('yearUsedMinutes'),
      yearLimitMinutes: n('yearLimitMinutes'),
    );
  }

  double get monthRatio => monthLimitMinutes == 0 ? 0 : (monthUsedMinutes / monthLimitMinutes).clamp(0.0, 1.0);
  double get yearRatio => yearLimitMinutes == 0 ? 0 : (yearUsedMinutes / yearLimitMinutes).clamp(0.0, 1.0);
}
