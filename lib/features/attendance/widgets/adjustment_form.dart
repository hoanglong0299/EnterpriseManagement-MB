import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/network/api_client.dart';
import '../../../core/utils/helpers.dart';
import '../../../services/attendance_service.dart';
import '../../../shared/widgets/wheel_time_picker.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/employee_attendance_provider.dart';

// Mở form yêu cầu chỉnh sửa chấm công; trả true nếu đã gửi thành công. [initialDate] điền sẵn ô ngày.
Future<bool?> showAdjustmentForm(BuildContext context, {DateTime? initialDate}) {
  final provider = EmployeeAttendanceProvider(
    AttendanceService(context.read<ApiClient>()),
    context.read<AuthProvider>(),
  );
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
    builder: (_) => AdjustmentForm(provider: provider, initialDate: initialDate),
  ).whenComplete(provider.dispose);
}

// ==========================================
// Form gửi yêu cầu điều chỉnh (bottom sheet)
// ==========================================
class AdjustmentForm extends StatefulWidget {
  final EmployeeAttendanceProvider provider;
  final DateTime? initialDate;
  const AdjustmentForm({super.key, required this.provider, this.initialDate});

  @override
  State<AdjustmentForm> createState() => AdjustmentFormState();
}

class AdjustmentFormState extends State<AdjustmentForm> {
  final _reasonController = TextEditingController();
  late DateTime _date = widget.initialDate ?? DateTime.now();
  // Mặc định giống web: 08:00 - 17:30; bỏ trống giờ nào thì giữ nguyên giờ đó.
  TimeOfDay? _checkIn = const TimeOfDay(hour: 8, minute: 0);
  TimeOfDay? _checkOut = const TimeOfDay(hour: 17, minute: 30);
  bool _sending = false;
  String? _error;

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime.now().subtract(const Duration(days: 366)),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _pickTime(bool isIn) async {
    final picked = await showWheelTimePicker(
      context,
      initial: (isIn ? _checkIn : _checkOut) ?? (isIn ? const TimeOfDay(hour: 8, minute: 0) : const TimeOfDay(hour: 17, minute: 30)),
      title: isIn ? 'Giờ vào đề xuất' : 'Giờ ra đề xuất',
    );
    if (picked != null) setState(() => isIn ? _checkIn = picked : _checkOut = picked);
  }

  Future<void> _submit() async {
    if (_reasonController.text.trim().isEmpty) {
      setState(() => _error = 'Vui lòng nhập lý do điều chỉnh.');
      return;
    }
    if (_checkIn == null && _checkOut == null) {
      setState(() => _error = 'Hãy đề xuất ít nhất một giờ vào hoặc giờ ra.');
      return;
    }
    setState(() {
      _sending = true;
      _error = null;
    });
    final error = await widget.provider.submitAdjustment(
      date: _date,
      reason: _reasonController.text.trim(),
      checkIn: _checkIn,
      checkOut: _checkOut,
    );
    if (!mounted) return;
    if (error == null) {
      Navigator.pop(context, true);
    } else {
      setState(() {
        _sending = false;
        _error = error;
      });
    }
  }

  Widget _timeField(String label, TimeOfDay? value, bool isIn) {
    return Expanded(
      child: InkWell(
        onTap: () => _pickTime(isIn),
        child: InputDecorator(
          decoration: InputDecoration(
            labelText: label,
            border: const OutlineInputBorder(),
            suffixIcon: value == null
                ? null
                : IconButton(
                    icon: const Icon(Icons.close, size: 18),
                    onPressed: () => setState(() => isIn ? _checkIn = null : _checkOut = null),
                  ),
          ),
          child: Text(value == null ? 'Bỏ trống' : value.format(context)),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + MediaQuery.of(context).viewInsets.bottom),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Yêu cầu chỉnh sửa chấm công', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            InkWell(
              onTap: _pickDate,
              child: InputDecorator(
                decoration: const InputDecoration(labelText: 'Ngày cần chỉnh sửa *', border: OutlineInputBorder()),
                child: Text(formatDate(_date)),
              ),
            ),
            const SizedBox(height: 12),
            Row(children: [
              _timeField('Giờ vào đề xuất', _checkIn, true),
              const SizedBox(width: 12),
              _timeField('Giờ ra đề xuất', _checkOut, false),
            ]),
            const SizedBox(height: 4),
            Text(
              'Bỏ trống giờ vào nếu quên chấm công ra, bỏ trống giờ ra nếu quên chấm công vào.',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _reasonController,
              maxLines: 3,
              decoration: const InputDecoration(labelText: 'Lý do *', border: OutlineInputBorder()),
            ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(_error!, style: const TextStyle(color: Colors.red)),
              ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF5A3FD8),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onPressed: _sending ? null : _submit,
                child: _sending
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('Gửi yêu cầu'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
