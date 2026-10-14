import 'package:flutter/material.dart';

class PrivacyStatementScreen extends StatelessWidget {
  const PrivacyStatementScreen({super.key});

  // Tách biệt dữ liệu văn bản thành một List cố định để code UI không bị rác
  static const List<Map<String, String>> _privacySections = [
    {
      'title': '1. Phạm vi thu thập dữ liệu',
      'content': 'Để đảm bảo chức năng chấm công chính xác, ứng dụng sẽ thu thập các thông tin sau khi nhận được sự cho phép của bạn:\n\n'
                 '• Dữ liệu vị trí (GPS): Chỉ thu thập đúng thời điểm bạn bấm nút "Chấm công vào/ra" để xác minh bạn đang ở nơi làm việc quy định.\n'
                 '• Dữ liệu sinh trắc học (khuôn mặt/vân tay): Hình ảnh hoặc dấu vân tay được thu thập để xác thực danh tính và ngăn chặn chấm công hộ.\n'
                 '• Dữ liệu thiết bị và hệ thống: Thông tin về loại thiết bị (Device ID), hệ điều hành, địa chỉ IP và thời gian truy cập được thu thập để ghi nhật ký hệ thống và bảo vệ tài khoản của bạn.',
    },
    {
      'title': '2. Mục đích sử dụng dữ liệu',
      'content': 'Toàn bộ dữ liệu thu thập từ người dùng chỉ được sử dụng cho mục đích nội bộ của doanh nghiệp, bao gồm:\n\n'
                 '• Xác minh danh tính, vị trí và thời gian làm việc thực tế của nhân viên.\n'
                 '• Cung cấp cơ sở dữ liệu chính xác cho phòng Nhân sự để tính lương, thưởng và quản lý ca làm việc.\n'
                 '• Ngăn chặn hành vi gian lận, giả mạo vị trí hoặc can thiệp vào thiết bị trong quá trình chấm công.',
    },
    {
      'title': '3. Cam kết không tiết lộ',
      'content': 'Chúng tôi cam kết tuyệt đối không bán, trao đổi, cho thuê hoặc cung cấp dữ liệu cá nhân, dữ liệu vị trí và dữ liệu sinh trắc học của bạn cho bất kỳ bên thứ ba nào vì mục đích thương mại. Dữ liệu của bạn chỉ được chia sẻ trong phạm vi sau:\n\n'
                 '• Quản lý, Quản trị viên hệ thống (Admin) hoặc phòng Nhân sự của công ty/tổ chức trực tiếp quản lý bạn.\n'
                 '• Các đối tác hạ tầng máy chủ đám mây đã ký thỏa thuận bảo mật (NDA) nghiêm ngặt với chúng tôi.',
    },
    {
      'title': '4. Biện pháp bảo mật và mã hóa',
      'content': 'Ứng dụng áp dụng các tiêu chuẩn bảo mật kỹ thuật số tiên tiến nhất hiện có. Mọi thông tin cá nhân, đặc biệt là dữ liệu sinh trắc học và vị trí, được bảo vệ bằng mã hóa đầu cuối trong quá trình truyền tải và lưu trữ trên máy chủ. Chúng tôi sử dụng tường lửa và các giao thức bảo mật chặt chẽ để ngăn chặn mọi truy cập, thay đổi hoặc phá hủy dữ liệu trái phép từ bên ngoài.',
    },
    {
      'title': '5. Thời gian lưu trữ dữ liệu',
      'content': 'Dữ liệu chấm công và hồ sơ cá nhân của bạn sẽ được lưu trong hệ thống chừng nào bạn còn làm việc tại công ty. Khi hợp đồng lao động chấm dứt, dữ liệu sinh trắc học và tài khoản của bạn sẽ bị vô hiệu hóa, lưu trữ hoặc xóa vĩnh viễn theo chính sách quản lý hồ sơ nhân sự của công ty và quy định pháp luật hiện hành.',
    },
    {
      'title': '6. Quyền kiểm soát của người dùng',
      'content': 'Người dùng được quyền xem lại toàn bộ lịch sử chấm công, gồm thời gian và vị trí đã ghi nhận, ngay trong ứng dụng. Nếu phát hiện thông tin không chính xác hoặc muốn yêu cầu chỉnh sửa/xóa dữ liệu khuôn mặt/vân tay, bạn có quyền gửi yêu cầu trực tiếp đến Quản trị viên hệ thống hoặc phòng Nhân sự của công ty để được giải quyết theo thẩm quyền.',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Chính sách quyền riêng tư'),
        backgroundColor: const Color(0xFF5A3FD8),
        elevation: 0,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(20.0),
        itemCount: _privacySections.length,
        itemBuilder: (context, index) {
          final section = _privacySections[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  section['title']!,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF5A3FD8),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  section['content']!,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.black87,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}