import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../app/theme.dart';
import '../../../core/utils/vi_date.dart';
import '../../../models/attendance_record.dart';

const double _goalHours = 8;

// Thẻ gradient: trạng thái hôm nay, đồng hồ, vòng tiến độ 8 giờ và giờ vào/ra/giờ làm.
class WorkSummaryCard extends StatefulWidget {
  final AttendanceRecord? record;

  const WorkSummaryCard({super.key, required this.record});

  @override
  State<WorkSummaryCard> createState() => _WorkSummaryCardState();
}

class _WorkSummaryCardState extends State<WorkSummaryCard> {
  Timer? _timer;
  DateTime _now = DateTime.now();

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _now = DateTime.now());
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  // Số giờ đã làm: đang làm thì tính tới bây giờ, đã ra thì tới giờ ra; trừ giờ nghỉ trưa 12:00-13:00.
  double _workedHours() {
    final r = widget.record;
    final start = r?.checkInTime?.toLocal();
    if (start == null) return 0;
    final end = r!.checkOutTime?.toLocal() ?? _now;
    if (!end.isAfter(start)) return 0;

    var minutes = end.difference(start).inMinutes.toDouble();
    final lunchStart = DateTime(start.year, start.month, start.day, 12);
    final lunchEnd = DateTime(start.year, start.month, start.day, 13);
    final overlapStart = start.isAfter(lunchStart) ? start : lunchStart;
    final overlapEnd = end.isBefore(lunchEnd) ? end : lunchEnd;
    if (overlapEnd.isAfter(overlapStart)) minutes -= overlapEnd.difference(overlapStart).inMinutes;
    return math.max(0, minutes) / 60;
  }

  ({String label, Color color}) _status() {
    final r = widget.record;
    if (r == null || r.checkInTime == null) {
      if (r?.status == 'OnLeave') return (label: 'Nghỉ phép', color: const Color(0xFF7DD3FC));
      return (label: 'Chưa chấm công', color: Colors.white54);
    }
    if (r.checkOutTime != null) return (label: 'Đã chấm công ra', color: const Color(0xFFC4B5FD));
    if (r.status == 'Late') return (label: 'Đang làm việc · đi muộn', color: const Color(0xFFFCD34D));
    return (label: 'Đang làm việc', color: const Color(0xFF86EFAC));
  }

  String _hm(DateTime? t) => t == null ? '--:--' : DateFormat('HH:mm').format(t.toLocal());

  String _duration(double hours) {
    final total = (hours * 60).round();
    return '${total ~/ 60}g ${(total % 60).toString().padLeft(2, '0')}p';
  }

  @override
  Widget build(BuildContext context) {
    final r = widget.record;
    final worked = _workedHours();
    final status = _status();

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: AppColors.heroGradient,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [BoxShadow(color: AppColors.primary.withValues(alpha: 0.35), blurRadius: 22, offset: const Offset(0, 10))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.14), borderRadius: BorderRadius.circular(20)),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 7,
                  height: 7,
                  decoration: BoxDecoration(color: status.color, shape: BoxShape.circle),
                ),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(status.label, style: const TextStyle(color: Colors.white, fontSize: 11.5)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Thu nhỏ đồng hồ khi chữ hệ thống phóng to để không tràn ngang.
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        DateFormat('HH:mm').format(_now),
                        style: const TextStyle(color: Colors.white, fontSize: 40, fontWeight: FontWeight.w700, height: 1),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${viWeekdayFull(_now.weekday)}, ${viLongDate(_now)}',
                      style: const TextStyle(color: Colors.white70, fontSize: 12.5),
                    ),
                  ],
                ),
              ),
              _GoalRing(progress: worked / _goalHours),
            ],
          ),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(14)),
            child: IntrinsicHeight(
              child: Row(
                children: [
                  _stat('Giờ vào', _hm(r?.checkInTime)),
                  _divider(),
                  _stat('Giờ ra', _hm(r?.checkOutTime)),
                  _divider(),
                  _stat('Giờ làm', _duration(worked)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _stat(String label, String value) {
    return Expanded(
      child: Column(
        children: [
          Text(label, style: const TextStyle(color: Colors.white60, fontSize: 11.5)),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _divider() => VerticalDivider(width: 1, thickness: 1, color: Colors.white.withValues(alpha: 0.18));
}

class _GoalRing extends StatelessWidget {
  final double progress;

  const _GoalRing({required this.progress});

  @override
  Widget build(BuildContext context) {
    final value = progress.clamp(0.0, 1.0).toDouble();
    return SizedBox(
      width: 74,
      height: 74,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: 74,
            height: 74,
            child: CircularProgressIndicator(
              value: value,
              strokeWidth: 6,
              strokeCap: StrokeCap.round,
              backgroundColor: Colors.white.withValues(alpha: 0.2),
              valueColor: const AlwaysStoppedAnimation(Colors.white),
            ),
          ),
          // Chữ trong vòng thu nhỏ vừa lòng vòng khi chữ hệ thống phóng to.
          Padding(
            padding: const EdgeInsets.all(10),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Mục tiêu', style: TextStyle(color: Colors.white70, fontSize: 10)),
                  Text(
                    '${_goalHours.round()}g',
                    style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
