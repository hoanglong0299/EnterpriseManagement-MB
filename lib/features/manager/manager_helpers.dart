import 'package:flutter/material.dart';

import '../../shared/widgets/status_chip.dart';

// Nhãn + màu trạng thái chấm công dùng chung cho các màn hình manager (giống attendanceLabels bên web).
const Map<String, String> attendanceLabels = {
  'Present': 'Đúng giờ',
  'Late': 'Đi muộn',
  'HalfDay': 'Nửa ngày',
  'HalfDayAbsent': 'Vắng nửa buổi sáng',
  'Absent': 'Vắng mặt',
  'OnLeave': 'Nghỉ phép',
};

String attendanceLabel(String status) => attendanceLabels[status] ?? 'Chưa chấm công';

Color attendanceColor(String status) {
  switch (status) {
    case 'Present':
      return StatusChip.success;
    case 'Late':
    case 'HalfDay':
      return StatusChip.warning;
    case 'Absent':
    case 'HalfDayAbsent':
      return StatusChip.danger;
    case 'OnLeave':
      return StatusChip.info;
    default:
      return StatusChip.neutral;
  }
}

const Color managerPrimary = Color(0xFF2A5CAA);
const Color managerBackground = Color(0xFFF5F7FA);

// Khung Scaffold chung: AppBar xanh đúng phong cách các màn hình khác.
AppBar managerAppBar(String title, {List<Widget>? actions, PreferredSizeWidget? bottom}) => AppBar(
      title: Text(title),
      backgroundColor: managerPrimary,
      foregroundColor: Colors.white,
      actions: actions,
      bottom: bottom,
    );
