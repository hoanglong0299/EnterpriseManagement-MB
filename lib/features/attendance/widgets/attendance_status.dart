import 'package:flutter/material.dart';

import '../../../shared/widgets/status_chip.dart';

// Nhãn + màu trạng thái chấm công / yêu cầu điều chỉnh, khớp attendanceLabels/attendanceColors của web.
const Map<String, String> attendanceLabels = {
  'Present': 'Đúng giờ',
  'Late': 'Đi muộn',
  'HalfDay': 'Nửa ngày',
  'HalfDayAbsent': 'Vắng nửa buổi sáng',
  'Absent': 'Vắng mặt',
  'OnLeave': 'Nghỉ phép',
  'None': 'Chưa có dữ liệu',
};

const Map<String, String> requestLabels = {
  'Pending': 'Chờ duyệt',
  'Approved': 'Đã duyệt',
  'Confirmed': 'Đã xác nhận',
  'Completed': 'Hoàn tất',
  'Rejected': 'Từ chối',
  'Cancelled': 'Đã hủy',
};

// Nhãn 4 trạng thái yêu cầu điều chỉnh công (2 bước: Manager xác nhận, HR áp dụng).
const Map<String, String> adjustmentLabels = {
  'Pending': 'Chờ quản lý duyệt',
  'PendingHr': 'Chờ HR xử lý',
  'Approved': 'Đã áp dụng',
  'Rejected': 'Từ chối',
};

Color adjustmentColor(String status) {
  switch (status) {
    case 'Pending':
      return StatusChip.warning;
    case 'PendingHr':
      return StatusChip.info;
    case 'Approved':
      return StatusChip.success;
    case 'Rejected':
      return StatusChip.danger;
    default:
      return StatusChip.neutral;
  }
}

// Trạng thái từng buổi do backend tính (None, OnTime, Late, Absent, OnLeave).
const Map<String, String> sessionStatusLabels = {
  'OnTime': 'Đúng giờ',
  'Late': 'Đi muộn',
  'Absent': 'Vắng',
  'OnLeave': 'Nghỉ phép',
  'None': 'Chưa có',
};

// Khi sáng và chiều khác nhau (và có dữ liệu) thì trả chuỗi "Sáng: ... · Chiều: ..."; ngược lại null (dùng chip cả ngày).
String? sessionSummaryText(String morning, String afternoon) {
  if (morning == afternoon || (morning == 'None' && afternoon == 'None')) return null;
  return 'Sáng: ${sessionStatusLabels[morning] ?? morning} · Chiều: ${sessionStatusLabels[afternoon] ?? afternoon}';
}

String attendanceLabel(String status) => attendanceLabels[status] ?? status;

Color attendanceColor(String status) {
  switch (status) {
    case 'Present':
      return StatusChip.success;
    case 'Late':
    case 'HalfDay':
      return StatusChip.warning;
    case 'HalfDayAbsent':
    case 'Absent':
      return StatusChip.danger;
    case 'OnLeave':
      return StatusChip.info;
    default:
      return StatusChip.neutral;
  }
}

Color requestColor(String status) {
  switch (status) {
    case 'Pending':
      return StatusChip.warning;
    case 'Approved':
    case 'Confirmed':
    case 'Completed':
      return StatusChip.success;
    case 'Rejected':
      return StatusChip.danger;
    default:
      return StatusChip.neutral;
  }
}

class RequestStatusChip extends StatelessWidget {
  final String status;
  const RequestStatusChip({super.key, required this.status});

  @override
  Widget build(BuildContext context) =>
      StatusChip(label: requestLabels[status] ?? status, color: requestColor(status));
}

class AdjustmentStatusChip extends StatelessWidget {
  final String status;
  const AdjustmentStatusChip({super.key, required this.status});

  @override
  Widget build(BuildContext context) =>
      StatusChip(label: adjustmentLabels[status] ?? status, color: adjustmentColor(status));
}
