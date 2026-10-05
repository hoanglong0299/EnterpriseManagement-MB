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
};

const Map<String, String> requestLabels = {
  'Pending': 'Chờ duyệt',
  'Approved': 'Đã duyệt',
  'Confirmed': 'Đã xác nhận',
  'Completed': 'Hoàn tất',
  'Rejected': 'Từ chối',
  'Cancelled': 'Đã hủy',
};

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

class AttendanceStatusChip extends StatelessWidget {
  final String status;
  const AttendanceStatusChip({super.key, required this.status});

  @override
  Widget build(BuildContext context) =>
      StatusChip(label: attendanceLabel(status), color: attendanceColor(status));
}

class RequestStatusChip extends StatelessWidget {
  final String status;
  const RequestStatusChip({super.key, required this.status});

  @override
  Widget build(BuildContext context) =>
      StatusChip(label: requestLabels[status] ?? status, color: requestColor(status));
}
