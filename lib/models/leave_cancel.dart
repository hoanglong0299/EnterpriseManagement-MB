import 'package:intl/intl.dart';

// Yêu cầu hủy một đơn nghỉ phép đã duyệt nhưng chưa bắt đầu (LeaveCancelRequestDto của backend).
class LeaveCancelRequest {
  final int id;
  final int leaveRequestId;
  final String employeeCode;
  final String employeeName;
  final String leaveTypeName;
  final DateTime startDate;
  final DateTime endDate;
  final String? session;
  final double totalTime;
  final String unit;
  final String reason;
  final String status; // Pending | Approved | Rejected | Withdrawn
  final String? managerName;
  final DateTime? decidedAt;
  final String? rejectionReason;
  final DateTime createdAt;

  LeaveCancelRequest({
    required this.id,
    required this.leaveRequestId,
    required this.employeeCode,
    required this.employeeName,
    required this.leaveTypeName,
    required this.startDate,
    required this.endDate,
    this.session,
    required this.totalTime,
    required this.unit,
    required this.reason,
    required this.status,
    this.managerName,
    this.decidedAt,
    this.rejectionReason,
    required this.createdAt,
  });

  factory LeaveCancelRequest.fromJson(Map<String, dynamic> json) {
    return LeaveCancelRequest(
      id: (json['id'] as num).toInt(),
      leaveRequestId: (json['leaveRequestId'] as num).toInt(),
      employeeCode: json['employeeCode'] as String? ?? '',
      employeeName: json['employeeName'] as String? ?? '',
      leaveTypeName: json['leaveTypeName'] as String? ?? '',
      startDate: DateTime.parse(json['startDate'] as String),
      endDate: DateTime.parse(json['endDate'] as String),
      session: json['session'] as String?,
      totalTime: (json['totalTime'] as num?)?.toDouble() ?? 0,
      unit: json['unit'] as String? ?? 'Days',
      reason: json['reason'] as String? ?? '',
      status: json['status'] as String? ?? 'Pending',
      managerName: json['managerName'] as String?,
      decidedAt: json['decidedAt'] == null ? null : DateTime.parse(json['decidedAt'] as String),
      rejectionReason: json['rejectionReason'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  bool get isPending => status == 'Pending';

  String get statusLabel => leaveCancelStatusLabels[status] ?? status;

  String get dateLabel {
    final f = DateFormat('dd/MM/yyyy');
    final s = f.format(startDate);
    final e = f.format(endDate);
    return s == e ? s : '$s - $e';
  }

  String get durationLabel {
    final t = totalTime == totalTime.roundToDouble() ? totalTime.toInt().toString() : totalTime.toString();
    return '$t ${unit == 'Hours' ? 'giờ' : 'ngày'}';
  }
}

const Map<String, String> leaveCancelStatusLabels = {
  'Pending': 'Chờ duyệt hủy',
  'Approved': 'Đã hủy',
  'Rejected': 'Từ chối hủy',
  'Withdrawn': 'Đã rút lại',
};
