import '../models/check_in_record.dart';

class CheckInService {
  Future<bool> submitCheckIn(CheckInRecord record) async {
    // Giả lập thời gian gửi request lên máy chủ (1 giây)
    await Future.delayed(const Duration(seconds: 1));
    
    // Luôn trả về true (Chấm công thành công)
    return true; 
  }
}