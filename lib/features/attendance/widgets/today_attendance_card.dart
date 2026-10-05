import 'package:flutter/material.dart';

import '../../../core/utils/helpers.dart';
import '../../../models/attendance_record.dart';
import '../../../shared/widgets/permission_gate.dart';
import '../../check_in/screens/check_in_screen.dart';
import 'attendance_status.dart';

// Thẻ "Chấm công hôm nay" dùng chung cho Dashboard và màn hình Chấm công.
// Nút mở màn hình chấm công thật (GPS + ảnh) chỉ hiện khi có quyền attendance.punch.
class TodayAttendanceCard extends StatelessWidget {
  final AttendanceRecord? today;
  // Gọi sau khi quay về từ màn hình chấm công để làm mới số liệu.
  final VoidCallback onReturn;

  const TodayAttendanceCard({super.key, required this.today, required this.onReturn});

  @override
  Widget build(BuildContext context) {
    final t = today;
    // Lần chấm đầu trong ngày là Check-in, các lần sau là Check-out (khớp backend).
    final nextAction = t?.checkInTime == null ? 'Check-in' : 'Check-out';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.access_time_filled, color: Color(0xFF2A5CAA)),
              const SizedBox(width: 8),
              const Expanded(child: Text('Chấm công hôm nay', style: TextStyle(fontWeight: FontWeight.w600))),
              if (t != null)
                AttendanceStatusChip(status: t.status)
              else
                const Text('Chưa chấm công', style: TextStyle(color: Colors.grey, fontSize: 12)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _timeBox('Vào', formatTime(t?.checkInTime))),
              const SizedBox(width: 12),
              Expanded(child: _timeBox('Ra', formatTime(t?.checkOutTime))),
            ],
          ),
          PermissionGate(
            code: 'attendance.punch',
            child: Padding(
              padding: const EdgeInsets.only(top: 12),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2A5CAA),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  icon: const Icon(Icons.fingerprint),
                  label: Text(nextAction),
                  onPressed: () async {
                    await Navigator.push(context, MaterialPageRoute(builder: (_) => const CheckInScreen()));
                    onReturn();
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _timeBox(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
      decoration: BoxDecoration(color: const Color(0xFFF5F7FA), borderRadius: BorderRadius.circular(10)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
          const SizedBox(height: 2),
          Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
