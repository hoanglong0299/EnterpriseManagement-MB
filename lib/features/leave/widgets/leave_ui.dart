import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../models/leave_request.dart';
import '../../../shared/widgets/status_chip.dart';

// Phần giao diện dùng chung cho màn nghỉ phép của nhân viên và quản lý.

Color leaveStatusColor(String status) {
  switch (status) {
    case 'Approved':
      return StatusChip.success;
    case 'Pending':
      return StatusChip.warning;
    case 'Rejected':
      return StatusChip.danger;
    default:
      return StatusChip.neutral;
  }
}

class LeaveStatusChip extends StatelessWidget {
  final LeaveRequest request;
  const LeaveStatusChip(this.request, {super.key});

  @override
  Widget build(BuildContext context) =>
      StatusChip(label: request.statusLabel, color: leaveStatusColor(request.status));
}

// Bộ lọc trạng thái dạng chip ngang; value null = tất cả.
const leaveStatusFilters = <String?, String>{
  null: 'Tất cả',
  'Pending': 'Chờ duyệt',
  'Approved': 'Đã duyệt',
  'Rejected': 'Từ chối',
  'Cancelled': 'Đã hủy',
};

class LeaveStatusFilterBar extends StatelessWidget {
  final String? selected;
  final ValueChanged<String?> onChanged;
  const LeaveStatusFilterBar({super.key, required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        children: [
          for (final entry in leaveStatusFilters.entries)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                label: Text(entry.value),
                selected: selected == entry.key,
                onSelected: (_) => onChanged(entry.key),
              ),
            ),
        ],
      ),
    );
  }
}

// Bảng chi tiết 1 đơn nghỉ (dùng chung cho nhân viên/quản lý).
void showLeaveDetail(BuildContext context, LeaveRequest r, {bool showEmployee = false}) {
  Widget row(String label, String? value) {
    if (value == null || value.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 110, child: Text(label, style: const TextStyle(color: Colors.grey))),
          Expanded(child: Text(value, style: const TextStyle(fontWeight: FontWeight.w500))),
        ],
      ),
    );
  }

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
    builder: (_) => SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text('Chi tiết đơn nghỉ',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF2A5CAA))),
                ),
                LeaveStatusChip(r),
              ],
            ),
            const Divider(height: 24),
            if (showEmployee) row('Nhân viên', r.employeeCode.isEmpty ? r.employeeName : '${r.employeeName} (${r.employeeCode})'),
            row('Loại nghỉ', r.leaveTypeName),
            row('Ngày nghỉ', r.dateLabel),
            row('Thời gian', r.timeLabel),
            row('Tổng thời gian', r.durationLabel),
            row('Lý do', r.reason),
            row('Người duyệt', r.approverName),
            row('Xử lý lúc', r.approvedAt == null ? null : DateFormat('dd/MM/yyyy HH:mm').format(r.approvedAt!)),
            row('Lý do từ chối', r.rejectionReason),
          ],
        ),
      ),
    ),
  );
}
