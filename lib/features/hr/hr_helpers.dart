import 'package:flutter/material.dart';

import '../../shared/widgets/status_chip.dart';

// Màu/nhãn dùng chung cho các màn hình HR (cùng phong cách màn hình manager).
const Color hrPrimary = Color(0xFF5A3FD8);
const Color hrBackground = Color(0xFFF6F4FC);
const Color hrAmber = Color(0xFFF9A825);
const Color hrGrey = Color(0xFF757575);

AppBar hrAppBar(String title, {List<Widget>? actions}) => AppBar(
      title: Text(title),
      backgroundColor: hrPrimary,
      foregroundColor: Colors.white,
      actions: actions,
    );

// Trạng thái một buổi do backend tính: None, OnTime, Late, Absent, OnLeave.
String sessionStatusLabel(String s) {
  switch (s) {
    case 'OnTime':
      return 'Đúng giờ';
    case 'Late':
      return 'Đi muộn';
    case 'Absent':
      return 'Vắng';
    case 'OnLeave':
      return 'Nghỉ phép';
    default:
      return '--';
  }
}

Color sessionStatusColor(String s) {
  switch (s) {
    case 'OnTime':
      return StatusChip.success;
    case 'Late':
      return hrAmber;
    case 'Absent':
      return StatusChip.danger;
    case 'OnLeave':
      return hrGrey;
    default:
      return StatusChip.neutral;
  }
}

String sessionName(String s) => s == 'Morning' ? 'Sáng' : (s == 'Afternoon' ? 'Chiều' : 'Cả ngày');

// Chuỗi ngày yyyy-MM-dd hoặc ISO -> DateTime (null nếu không đọc được).
DateTime? parseDay(String v) => DateTime.tryParse(v);

// Vòng xoay nhỏ trong nút khi đang xử lý.
Widget busyIndicator() => const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white));

// Hộp nhập lý do từ chối. Trả về null nếu huỷ, chuỗi (có thể rỗng) nếu đồng ý.
Future<String?> askReason(BuildContext context, {required String title, String confirmText = 'Từ chối'}) {
  final controller = TextEditingController();
  return showDialog<String>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(title),
      content: TextField(
        controller: controller,
        autofocus: true,
        maxLines: 3,
        decoration: const InputDecoration(labelText: 'Lý do', border: OutlineInputBorder()),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Huỷ')),
        TextButton(
          onPressed: () => Navigator.pop(ctx, controller.text.trim()),
          child: Text(confirmText, style: const TextStyle(color: Colors.red)),
        ),
      ],
    ),
  );
}
