import 'package:intl/intl.dart';

class LeaveRequest {
  final int id;
  final String employeeName;
  final String leaveTypeCode;
  final String leaveTypeName;
  final DateTime startDate;
  final DateTime endDate;
  final String? session;
  final String unit;
  final double totalTime;
  final String? reason;
  final String status;
  final String? approverName;
  final String? rejectionReason;

  LeaveRequest({
    required this.id,
    required this.employeeName,
    required this.leaveTypeCode,
    required this.leaveTypeName,
    required this.startDate,
    required this.endDate,
    this.session,
    required this.unit,
    required this.totalTime,
    this.reason,
    required this.status,
    this.approverName,
    this.rejectionReason,
  });

  factory LeaveRequest.fromJson(Map<String, dynamic> json) {
    return LeaveRequest(
      id: json['id'] as int,
      employeeName: json['employeeName'] as String,
      leaveTypeCode: json['leaveTypeCode'] as String,
      leaveTypeName: json['leaveTypeName'] as String,
      startDate: DateTime.parse(json['startDate'] as String),
      endDate: DateTime.parse(json['endDate'] as String),
      session: json['session'] as String?,
      unit: json['unit'] as String,
      totalTime: (json['totalTime'] as num).toDouble(),
      reason: json['reason'] as String?,
      status: json['status'] as String,
      approverName: json['approverName'] as String?,
      rejectionReason: json['rejectionReason'] as String?,
    );
  }

  bool get isPending => status == 'Pending';

  // Mot ngay thi "dd/MM/yyyy", nhieu ngay thi "dd/MM/yyyy - dd/MM/yyyy".
  String get dateLabel {
    final format = DateFormat('dd/MM/yyyy');
    final start = format.format(startDate);
    final end = format.format(endDate);
    return start == end ? start : '$start - $end';
  }

  // Don chon buoi (khop nhan ben web), con nghi ngan (khong co buoi) thi hien gio bat dau - ket thuc.
  String get timeLabel {
    switch (session) {
      case 'Morning':
        return 'Buổi sáng (08:00-12:00)';
      case 'Afternoon':
        return 'Buổi chiều (13:00-17:00)';
      case 'FullDay':
        return 'Cả ngày';
      default:
        final time = DateFormat('HH:mm');
        return '${time.format(startDate)} - ${time.format(endDate)}';
    }
  }

  String get durationLabel {
    final number = totalTime == totalTime.roundToDouble()
        ? totalTime.toInt().toString()
        : totalTime.toString().replaceAll('.', ',');
    return '$number ${unit == 'Hours' ? 'giờ' : 'ngày'}';
  }

  String get statusLabel {
    switch (status) {
      case 'Pending':
        return 'Chờ duyệt';
      case 'Approved':
        return 'Đã duyệt';
      case 'Rejected':
        return 'Từ chối';
      case 'Cancelled':
        return 'Đã hủy';
      default:
        return status;
    }
  }
}
