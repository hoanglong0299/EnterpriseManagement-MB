import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class CheckInProvider extends ChangeNotifier {
  bool _isLoading = false;
  
  // Trạng thái khóa nút: false = chưa Clock In, true = đã Clock In
  bool _hasClockedIn = false; 
  
  // Lịch sử ảo có sẵn
  final List<String> _historyRecords = [
    '17.50 at Singapore Office (OUT)',
    '08.35 at Singapore Office (IN)',
  ];

  bool get isLoading => _isLoading;
  bool get hasClockedIn => _hasClockedIn;
  List<String> get historyRecords => _historyRecords;

  // Xử lý khi bấm nút CLOCK IN hoặc CLOCK OUT
  Future<void> performAction(String actionType) async {
    _isLoading = true;
    notifyListeners();

    // Giả lập thời gian xử lý của hệ thống (1 giây)
    await Future.delayed(const Duration(seconds: 1));
    
    // Đảo trạng thái nút bấm
    if (actionType == 'CLOCK IN') {
      _hasClockedIn = true; // Khóa nút Clock In, Mở nút Clock Out
    } else {
      _hasClockedIn = false; // Mở lại nút Clock In
    }

    // Lấy giờ hiện tại và thêm vào danh sách lịch sử
    final currentTime = DateFormat('HH.mm').format(DateTime.now());
    final type = actionType == 'CLOCK IN' ? 'IN' : 'OUT';
    _historyRecords.insert(0, '$currentTime at Singapore Office ($type)');

    _isLoading = false;
    notifyListeners();
  }
}