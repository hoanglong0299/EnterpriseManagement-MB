import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../core/network/api_client.dart';
import '../../../models/attendance_hr.dart';
import '../../../services/hr_service.dart';
import '../../../shared/widgets/confirm_dialog.dart';
import '../../../shared/widgets/state_views.dart';
import '../widgets/leave_return_ui.dart';

// Màn "Đi làm lại" của nhân viên: gửi yêu cầu (ngày + buổi + lý do, có xem trước) và xem các yêu cầu của tôi.
class LeaveReturnScreen extends StatefulWidget {
  const LeaveReturnScreen({super.key});

  @override
  State<LeaveReturnScreen> createState() => _LeaveReturnScreenState();
}

class _LeaveReturnScreenState extends State<LeaveReturnScreen> {
  late final HrService _service;
  final _reasonController = TextEditingController();
  final _dateFormat = DateFormat('dd/MM/yyyy');

  DateTime? _date;
  String _session = 'Morning';

  LeaveReturnPreview? _preview;
  String? _previewError;
  bool _previewing = false;
  int _previewSeq = 0; // bỏ qua kết quả xem trước cũ khi người dùng đổi ngày/buổi liên tục

  List<LeaveReturnRequest> _mine = [];
  bool _loadingMine = true;
  String? _mineError;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _service = HrService(context.read<ApiClient>());
    _loadMine();
  }

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _loadMine() async {
    setState(() {
      _loadingMine = true;
      _mineError = null;
    });
    try {
      final items = await _service.getMyReturns();
      if (!mounted) return;
      setState(() => _mine = items..sort((a, b) => b.id.compareTo(a.id)));
    } catch (e) {
      if (!mounted) return;
      setState(() => _mineError = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _loadingMine = false);
    }
  }

  // Gọi xem trước mỗi khi đã có đủ ngày + buổi; lỗi backend hiện nguyên văn.
  Future<void> _loadPreview() async {
    final date = _date;
    if (date == null) return;
    final seq = ++_previewSeq;
    setState(() {
      _previewing = true;
      _preview = null;
      _previewError = null;
    });
    try {
      final preview = await _service.previewReturn(date, _session);
      if (!mounted || seq != _previewSeq) return;
      setState(() => _preview = preview);
    } catch (e) {
      if (!mounted || seq != _previewSeq) return;
      setState(() => _previewError = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted && seq == _previewSeq) setState(() => _previewing = false);
    }
  }

  Future<void> _pickDate() async {
    final today = DateTime.now();
    final first = DateTime(today.year, today.month, today.day);
    final picked = await showDatePicker(
      context: context,
      initialDate: _date ?? first,
      firstDate: first,
      lastDate: DateTime(today.year + 1, today.month, today.day),
    );
    if (picked == null) return;
    setState(() => _date = picked);
    _loadPreview();
  }

  Future<void> _submit() async {
    final date = _date;
    final reason = _reasonController.text.trim();
    if (date == null || _preview == null) return;
    if (reason.isEmpty) return showMessage(context, 'Vui lòng nhập lý do đi làm lại.', error: true);
    if (_submitting) return;

    setState(() => _submitting = true);
    String? error;
    try {
      await _service.submitReturn(date, _session, reason);
    } catch (e) {
      error = e.toString().replaceFirst('Exception: ', '');
    }
    if (!mounted) return;
    setState(() => _submitting = false);
    if (error != null) {
      showMessage(context, error, error: true);
      return;
    }
    showMessage(context, 'Đã gửi yêu cầu đi làm lại.');
    setState(() {
      _date = null;
      _preview = null;
      _previewError = null;
      _reasonController.clear();
    });
    _loadMine();
  }

  String _num(double v) => v == v.roundToDouble() ? v.toInt().toString() : v.toString().replaceAll('.', ',');

  Widget _previewBox() {
    if (_date == null) {
      return const Text('Chọn ngày và buổi bắt đầu đi làm lại để xem trước.', style: TextStyle(color: Colors.grey));
    }
    if (_previewing) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 8),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (_previewError != null) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(8)),
        child: Text(_previewError!, style: TextStyle(color: Colors.red.shade800)),
      );
    }
    final p = _preview;
    if (p == null) return const SizedBox.shrink();
    final ids = p.leaveRequestIds.map((e) => '#$e').join(', ');
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: const Color(0xFFEFEBFF), borderRadius: BorderRadius.circular(8)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Sẽ đi làm lại ${p.sessionCount} buổi, thuộc đơn $ids, hoàn ${_num(p.refundDays)} ngày phép.',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          ReturnSessionList(sessions: p.sessions, showState: false),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final canSubmit = _preview != null && !_submitting;

    return Scaffold(
      backgroundColor: const Color(0xFFF6F4FC),
      appBar: AppBar(
        title: const Text('Đi làm lại'),
        backgroundColor: const Color(0xFF5A3FD8),
        foregroundColor: Colors.white,
      ),
      body: RefreshIndicator(
        onRefresh: _loadMine,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Gửi yêu cầu đi làm lại', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 4),
                    const Text(
                      'Dùng khi bạn đã được duyệt nghỉ nhưng muốn đi làm lại. Chỉ chọn được buổi chưa bắt đầu; '
                      'hệ thống tự đi làm lại đến hết đợt nghỉ liên tục.',
                      style: TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                    const SizedBox(height: 16),
                    const Text('Bắt đầu đi làm lại từ ngày', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    InkWell(
                      onTap: _pickDate,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                        decoration: BoxDecoration(border: Border.all(color: Colors.grey), borderRadius: BorderRadius.circular(4)),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(child: Text(_date == null ? 'Chọn ngày' : _dateFormat.format(_date!))),
                            const SizedBox(width: 4),
                            const Icon(Icons.calendar_today, size: 18, color: Colors.grey),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text('Buổi', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: _session,
                      isExpanded: true,
                      decoration: const InputDecoration(border: OutlineInputBorder()),
                      items: const [
                        DropdownMenuItem(value: 'Morning', child: Text('Buổi sáng (08:00-12:00)')),
                        DropdownMenuItem(value: 'Afternoon', child: Text('Buổi chiều (13:00-17:00)')),
                      ],
                      onChanged: (v) {
                        setState(() => _session = v ?? 'Morning');
                        _loadPreview();
                      },
                    ),
                    const SizedBox(height: 16),
                    _previewBox(),
                    const SizedBox(height: 16),
                    const Text('Lý do', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _reasonController,
                      maxLines: 3,
                      decoration: const InputDecoration(border: OutlineInputBorder(), hintText: 'Nhập lý do đi làm lại...'),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF5A3FD8),
                          foregroundColor: Colors.white,
                          minimumSize: const Size.fromHeight(48),
                        ),
                        onPressed: canSubmit ? _submit : null,
                        child: _submitting
                            ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                            : const Text('GỬI YÊU CẦU', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text('Yêu cầu đi làm lại của tôi', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 8),
            if (_loadingMine && _mine.isEmpty)
              const Padding(padding: EdgeInsets.all(24), child: Center(child: CircularProgressIndicator()))
            else if (_mineError != null && _mine.isEmpty)
              ErrorView(message: _mineError!, onRetry: _loadMine)
            else if (_mine.isEmpty)
              const Padding(
                padding: EdgeInsets.all(24),
                child: Center(child: Text('Chưa có yêu cầu đi làm lại.', style: TextStyle(color: Colors.grey))),
              )
            else
              for (final r in _mine) ReturnRequestCard(request: r),
          ],
        ),
      ),
    );
  }
}
