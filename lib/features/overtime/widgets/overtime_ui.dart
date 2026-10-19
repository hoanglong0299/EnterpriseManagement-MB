import 'package:flutter/material.dart';

import '../../../models/overtime.dart';
import '../../../shared/widgets/status_chip.dart';
import '../../attendance/widgets/capped_width.dart';

Color overtimeStatusColor(String status) {
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

class OvertimeStatusChip extends StatelessWidget {
  final OvertimeRequest request;
  const OvertimeStatusChip(this.request, {super.key});

  @override
  Widget build(BuildContext context) =>
      CappedWidth(child: StatusChip(label: request.statusLabel, color: overtimeStatusColor(request.status)));
}

// Nội dung một đơn OT (dùng chung cho nhân viên và quản lý). [actions] hiện dưới cùng nếu có.
class OvertimeCard extends StatelessWidget {
  final OvertimeRequest request;
  final bool showEmployee;
  final Widget? actions;

  const OvertimeCard({super.key, required this.request, this.showEmployee = false, this.actions});

  @override
  Widget build(BuildContext context) {
    final r = request;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    showEmployee ? r.employeeName : 'Ngày ${r.dateLabel}',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF5A3FD8)),
                  ),
                ),
                OvertimeStatusChip(r),
              ],
            ),
            const Divider(),
            if (showEmployee) Text('Ngày: ${r.dateLabel}'),
            Text('Thời gian: ${r.timeLabel} · ${r.durationLabel}'),
            const SizedBox(height: 4),
            Text('Lý do: ${r.reason}', style: const TextStyle(color: Colors.black54)),
            if (r.status == 'Approved' && r.approverName != null)
              Text('Người duyệt: ${r.approverName}', style: const TextStyle(color: Colors.black54)),
            if (r.status == 'Rejected' && (r.rejectionReason ?? '').isNotEmpty)
              Text('Lý do từ chối: ${r.rejectionReason}', style: const TextStyle(color: Colors.black54)),
            if (actions != null) ...[const SizedBox(height: 12), actions!],
          ],
        ),
      ),
    );
  }
}
