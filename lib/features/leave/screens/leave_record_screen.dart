import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

// ==========================================
// 1. MÀN HÌNH LỊCH SỬ ĐĂNG KÝ NGHỈ PHÉP
// ==========================================
class LeaveRecordScreen extends StatefulWidget {
  const LeaveRecordScreen({super.key});

  @override
  State<LeaveRecordScreen> createState() => _LeaveRecordScreenState();
}

class _LeaveRecordScreenState extends State<LeaveRecordScreen> {
  final List<Map<String, String>> _leaveHistory = [];

  void _navigateToApplyScreen() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const LeaveApplicationScreen()),
    );

    if (result != null && result is Map<String, String>) {
      setState(() {
        _leaveHistory.insert(0, result);
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đăng ký nghỉ phép thành công!'), backgroundColor: Colors.green),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text('Leave Record'),
        backgroundColor: const Color(0xFF2A5CAA),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ElevatedButton.icon(
              onPressed: _navigateToApplyScreen,
              icon: const Icon(Icons.add),
              label: const Text('ĐĂNG KÝ NGHỈ PHÉP', style: TextStyle(fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2A5CAA),
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
            const SizedBox(height: 24),
            
            const Text(
              'Lịch sử đăng ký',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
            ),
            const SizedBox(height: 12),

            Expanded(
              child: _leaveHistory.isEmpty
                  ? const Center(
                      child: Text(
                        'Không có dữ liệu',
                        style: TextStyle(color: Colors.grey, fontSize: 16, fontStyle: FontStyle.italic),
                      ),
                    )
                  : ListView.builder(
                      itemCount: _leaveHistory.length,
                      itemBuilder: (context, index) {
                        final record = _leaveHistory[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      record['type'] ?? '',
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF2A5CAA)),
                                    ),
                                    Text(
                                      record['appliedAt'] ?? '',
                                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                                    ),
                                  ],
                                ),
                                const Divider(),
                                const SizedBox(height: 4),
                                Text('Ngày nghỉ: ${record['date']}'),
                                if (record['time'] != null && record['time']!.isNotEmpty)
                                  Text('Thời gian: ${record['time']}'),
                                const SizedBox(height: 4),
                                Text('Lý do: ${record['reason']}', style: const TextStyle(color: Colors.black54)),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

// ==========================================
// 2. MÀN HÌNH ĐIỀN FORM ĐĂNG KÝ NGHỈ PHÉP
// ==========================================
class LeaveApplicationScreen extends StatefulWidget {
  const LeaveApplicationScreen({super.key});

  @override
  State<LeaveApplicationScreen> createState() => _LeaveApplicationScreenState();
}

class _LeaveApplicationScreenState extends State<LeaveApplicationScreen> {
  String _selectedLeaveType = 'Nghỉ phép';
  
  final TextEditingController _reasonController = TextEditingController();
  String _selectedPolicyReason = 'Kết hôn (Nghỉ 3 ngày)'; 
  
  DateTime? _selectedDate; // Dùng cho "Nghỉ phép" (1 ngày)
  DateTimeRange? _selectedDateRange; // Dùng cho "Nghỉ chế độ" (Khoảng ngày khứ hồi)
  
  TimeOfDay? _startTime; 
  TimeOfDay? _endTime;   

  final List<String> _policyReasons = [
    'Kết hôn (Nghỉ 3 ngày)',
    'Con kết hôn (Nghỉ 1 ngày)',
    'Người thân mất (Nghỉ 3 ngày)',
    'Nghỉ chế độ thai sản',
  ];

  // Mở lịch chọn 1 ngày (Dành cho Nghỉ phép)
  void _pickSingleDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  // Mở lịch chọn Khoảng ngày (Dành cho Nghỉ chế độ - Giống chọn vé máy bay)
  void _pickDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF2A5CAA), 
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _selectedDateRange = picked);
    }
  }

  // Chọn khoảng giờ (Bắt đầu -> Kết thúc)
  void _pickTimeRange() async {
    final start = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 8, minute: 0),
      helpText: 'CHỌN GIỜ BẮT ĐẦU NGHỈ',
    );
    
    if (start != null) {
      if (!mounted) return;
      final end = await showTimePicker(
        context: context,
        initialTime: const TimeOfDay(hour: 17, minute: 0),
        helpText: 'CHỌN GIỜ KẾT THÚC NGHỈ',
      );
      
      if (end != null) {
        setState(() {
          _startTime = start;
          _endTime = end;
        });
      }
    }
  }

  void _showConfirmationDialog() {
    // Validate dữ liệu
    if (_selectedLeaveType == 'Nghỉ phép' && _selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Vui lòng chọn ngày nghỉ')));
      return;
    }
    if (_selectedLeaveType == 'Nghỉ chế độ' && _selectedDateRange == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Vui lòng chọn khoảng thời gian nghỉ')));
      return;
    }
    if (_selectedLeaveType == 'Nghỉ phép' && _reasonController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Vui lòng nhập lý do')));
      return;
    }

    // Format ngày hiển thị tùy theo loại nghỉ
    String dateStr = '';
    if (_selectedLeaveType == 'Nghỉ phép') {
      dateStr = DateFormat('dd/MM/yyyy').format(_selectedDate!);
    } else {
      dateStr = '${DateFormat('dd/MM/yyyy').format(_selectedDateRange!.start)} - ${DateFormat('dd/MM/yyyy').format(_selectedDateRange!.end)}';
    }

    final String timeStr = (_startTime != null && _endTime != null) 
        ? '${_startTime!.format(context)} - ${_endTime!.format(context)}' 
        : 'Cả ngày';
    final String reasonStr = _selectedLeaveType == 'Nghỉ phép' ? _reasonController.text : _selectedPolicyReason;
    final String appliedAtStr = DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now());

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Xác nhận thông tin', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF2A5CAA))),
            const Divider(height: 30),
            _buildConfirmRow('Loại hình:', _selectedLeaveType),
            _buildConfirmRow('Lý do:', reasonStr),
            _buildConfirmRow('Ngày nghỉ:', dateStr),
            if (_selectedLeaveType == 'Nghỉ phép') _buildConfirmRow('Khung giờ:', timeStr),
            _buildConfirmRow('Thời gian tạo:', appliedAtStr),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('HỦY', style: TextStyle(color: Colors.grey)),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2A5CAA)),
                    onPressed: () {
                      Navigator.pop(context);
                      Navigator.pop(context, {
                        'type': _selectedLeaveType,
                        'reason': reasonStr,
                        'date': dateStr,
                        'time': _selectedLeaveType == 'Nghỉ phép' ? timeStr : '',
                        'appliedAt': appliedAtStr,
                      });
                    },
                    child: const Text('XÁC NHẬN'),
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _buildConfirmRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 100, child: Text(label, style: const TextStyle(color: Colors.grey))),
          Expanded(child: Text(value, style: const TextStyle(fontWeight: FontWeight.w500))),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Đăng ký nghỉ'),
        backgroundColor: const Color(0xFF2A5CAA),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Loại hình nghỉ phép', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _selectedLeaveType,
              decoration: const InputDecoration(border: OutlineInputBorder()),
              items: ['Nghỉ phép', 'Nghỉ chế độ']
                  .map((type) => DropdownMenuItem(value: type, child: Text(type)))
                  .toList(),
              onChanged: (value) {
                setState(() {
                  _selectedLeaveType = value!;
                });
              },
            ),
            const SizedBox(height: 20),

            // NẾU CHỌN "NGHỈ PHÉP"
            if (_selectedLeaveType == 'Nghỉ phép') ...[
              const Text('Lý do nghỉ', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              TextField(
                controller: _reasonController,
                maxLines: 3,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'Nhập lý do chi tiết...',
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Ngày nghỉ', style: TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        InkWell(
                          onTap: _pickSingleDate,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                            decoration: BoxDecoration(border: Border.all(color: Colors.grey), borderRadius: BorderRadius.circular(4)),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(_selectedDate != null ? DateFormat('dd/MM/yyyy').format(_selectedDate!) : 'Chọn ngày'),
                                const Icon(Icons.calendar_today, size: 18, color: Colors.grey),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  
                  Expanded(
                    flex: 1,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Khung giờ', style: TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        InkWell(
                          onTap: _pickTimeRange,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                            decoration: BoxDecoration(border: Border.all(color: Colors.grey), borderRadius: BorderRadius.circular(4)),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    (_startTime != null && _endTime != null) 
                                        ? '${_startTime!.format(context)} - ${_endTime!.format(context)}' 
                                        : 'Chọn giờ',
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const Icon(Icons.access_time, size: 18, color: Colors.grey),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],

            // NẾU CHỌN "NGHỈ CHẾ ĐỘ"
            if (_selectedLeaveType == 'Nghỉ chế độ') ...[
              const Text('Lý do nghỉ chế độ', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _selectedPolicyReason,
                isExpanded: true,
                decoration: const InputDecoration(border: OutlineInputBorder()),
                items: _policyReasons
                    .map((reason) => DropdownMenuItem(value: reason, child: Text(reason)))
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedPolicyReason = value!;
                  });
                },
              ),
              const SizedBox(height: 20),
              
              // KHUNG CHỌN KHOẢNG THỜI GIAN (TỪ NGÀY - ĐẾN NGÀY)
              const Text('Khoảng thời gian nghỉ', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              InkWell(
                onTap: _pickDateRange,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                  decoration: BoxDecoration(border: Border.all(color: Colors.grey), borderRadius: BorderRadius.circular(4)),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          _selectedDateRange != null 
                              ? '${DateFormat('dd/MM/yyyy').format(_selectedDateRange!.start)} - ${DateFormat('dd/MM/yyyy').format(_selectedDateRange!.end)}' 
                              : 'Chọn khoảng thời gian (Từ ngày - Đến ngày)',
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const Icon(Icons.date_range, size: 18, color: Colors.grey),
                    ],
                  ),
                ),
              ),
            ],
            
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2A5CAA)),
                onPressed: _showConfirmationDialog,
                child: const Text('TIẾP TỤC', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}