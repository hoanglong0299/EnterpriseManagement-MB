import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../auth/providers/auth_provider.dart';
import '../../auth/screens/login_screen.dart';
import '../../check_in/providers/check_in_provider.dart';
import '../../leave/providers/leave_provider.dart';
import '../providers/profile_provider.dart';
import 'privacy_statement_screen.dart';
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isNotificationOn = true;

  // Email/SĐT người dùng vừa sửa trong Account Settings. Backend chưa có API cho nhân viên tự sửa hồ sơ,
  // nên giá trị này chỉ giữ trong phiên chạy app; chưa sửa thì dùng dữ liệu thật từ hồ sơ.
  String? _emailOverride;
  String? _phoneOverride;

  String get _email => _emailOverride ?? context.read<ProfileProvider>().employee?.email ?? '';
  String get _phone => _phoneOverride ?? context.read<ProfileProvider>().employee?.phone ?? '';

  // Chuyển sang màn hình Cài đặt thông báo
  void _openNotificationSettings() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => NotificationSettingsScreen(initialValue: _isNotificationOn),
      ),
    );
    if (result != null) {
      setState(() {
        _isNotificationOn = result;
      });
    }
  }

  // Chuyển sang màn hình Cài đặt tài khoản
  void _openAccountSettings() async {
    final employee = context.read<ProfileProvider>().employee;
    final birthDate = employee?.dateOfBirth;

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AccountSettingsScreen(
          fullName: context.read<ProfileProvider>().displayName,
          birthDate: birthDate == null ? '' : DateFormat('dd/MM/yyyy').format(birthDate),
          email: _email,
          phone: _phone,
        ),
      ),
    );
    if (result != null) {
      setState(() {
        _emailOverride = result['email'];
        _phoneOverride = result['phone'];
      });
    }
  }

  // Đăng xuất
  void _handleLogout() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logging Out'),
        content: const Text('Are you sure you want to log out of the application?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () async {
              final navigator = Navigator.of(context);
              final auth = context.read<AuthProvider>();
              final checkIn = context.read<CheckInProvider>();
              final leave = context.read<LeaveProvider>();
              final profile = context.read<ProfileProvider>();

              // Xóa phiên đăng nhập (token) và dữ liệu đã tải của người dùng này
              await auth.logout();
              checkIn.clear();
              leave.clear();
              profile.clear();

              // Xóa toàn bộ stack màn hình hiện tại và quay về Login
              navigator.pushAndRemoveUntil(
                MaterialPageRoute(builder: (context) => const LoginScreen()),
                (route) => false,
              );
            },
            child: const Text('Đăng xuất', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final profile = context.watch<ProfileProvider>();

    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          // 1. Phần Header (Nền xanh + Avatar)
          SizedBox(
            height: 260,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                // Nền xanh
                Container(
                  height: 180,
                  color: const Color(0xFF2A5CAA),
                ),
                // Avatar và Camera icon
                Positioned(
                  top: 120,
                  left: 0,
                  right: 0,
                  child: Column(
                    children: [
                      Stack(
                        children: [
                          const CircleAvatar(
                            radius: 50,
                            backgroundColor: Colors.white,
                            child: CircleAvatar(
                              radius: 46,
                              backgroundImage: NetworkImage(
                                  'https://randomuser.me/api/portraits/men/32.jpg'), // Ảnh giả lập
                            ),
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: GestureDetector(
                              onTap: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Tính năng đổi ảnh đại diện đang phát triển')),
                                );
                              },
                              child: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF2A5CAA),
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.white, width: 2),
                                ),
                                child: const Icon(Icons.camera_alt, color: Colors.white, size: 16),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        profile.displayName,
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _email,
                        style: const TextStyle(fontSize: 14, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 10),

          // 2. Danh sách Menu Cài đặt
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _buildMenuItem(
                  icon: Icons.notifications_none,
                  title: 'Notification Settings',
                  trailingText: _isNotificationOn ? 'On' : 'Off',
                  onTap: _openNotificationSettings,
                ),
                _buildMenuItem(
                  icon: Icons.person_outline,
                  title: 'Account Settings',
                  onTap: _openAccountSettings,
                ),
                _buildMenuItem(
                  icon: Icons.description_outlined,
                  title: 'Privacy Statement',
                  onTap: () {
                    // Chuyển hướng sang màn hình Privacy Statement
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const PrivacyStatementScreen(),
                      ),
                    );
                  },
                ),
                _buildMenuItem(
                  icon: Icons.logout,
                  title: 'Logout',
                  hideBorder: true,
                  onTap: _handleLogout,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    String? trailingText,
    bool hideBorder = false,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          border: hideBorder ? null : const Border(bottom: BorderSide(color: Colors.black12, width: 1)),
        ),
        child: Row(
          children: [
            Icon(icon, color: const Color(0xFF2A5CAA), size: 24),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(fontSize: 15, color: Colors.black87),
              ),
            ),
            if (trailingText != null)
              Text(
                trailingText,
                style: const TextStyle(fontSize: 15, color: Colors.black87),
              ),
          ],
        ),
      ),
    );
  }
}

// ==========================================
// MÀN HÌNH CÀI ĐẶT THÔNG BÁO (NOTIFICATION)
// ==========================================
class NotificationSettingsScreen extends StatefulWidget {
  final bool initialValue;
  const NotificationSettingsScreen({super.key, required this.initialValue});

  @override
  State<NotificationSettingsScreen> createState() => _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState extends State<NotificationSettingsScreen> {
  late bool _isOn;

  @override
  void initState() {
    super.initState();
    _isOn = widget.initialValue;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notification Settings'),
        backgroundColor: const Color(0xFF2A5CAA),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context, _isOn), // Trả về trạng thái mới
        ),
      ),
      body: ListView(
        children: [
          SwitchListTile(
            title: const Text('Allow Notifications'),
            subtitle: const Text('Receive notifications about attendance, leave requests, OT...'),
            value: _isOn,
            activeColor: const Color(0xFF2A5CAA),
            onChanged: (value) {
              setState(() {
                _isOn = value;
              });
            },
          ),
        ],
      ),
    );
  }
}

// ==========================================
// MÀN HÌNH CÀI ĐẶT TÀI KHOẢN (ACCOUNT)
// ==========================================
class AccountSettingsScreen extends StatefulWidget {
  final String fullName;
  final String birthDate;
  final String email;
  final String phone;
  const AccountSettingsScreen({
    super.key,
    required this.fullName,
    required this.birthDate,
    required this.email,
    required this.phone,
  });

  @override
  State<AccountSettingsScreen> createState() => _AccountSettingsScreenState();
}

class _AccountSettingsScreenState extends State<AccountSettingsScreen> {
  late TextEditingController _emailController;
  late TextEditingController _phoneController;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController(text: widget.email);
    _phoneController = TextEditingController(text: widget.phone);
  }

  @override
  void dispose() {
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _saveSettings() {
    Navigator.pop(context, {
      'email': _emailController.text,
      'phone': _phoneController.text,
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Lưu thông tin thành công!'), backgroundColor: Colors.green),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Account Settings'),
        backgroundColor: const Color(0xFF2A5CAA),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Trường chỉ đọc
            _buildReadOnlyField('Họ và tên', widget.fullName),
            const SizedBox(height: 16),
            _buildReadOnlyField('Năm sinh', widget.birthDate),
            const SizedBox(height: 24),
            
            // Trường có thể sửa
            const Text('Email liên hệ', style: TextStyle(color: Colors.grey, fontSize: 13)),
            const SizedBox(height: 4),
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              ),
            ),
            const SizedBox(height: 16),
            
            const Text('Số điện thoại', style: TextStyle(color: Colors.grey, fontSize: 13)),
            const SizedBox(height: 4),
            TextField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              ),
            ),
            
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2A5CAA)),
                onPressed: _saveSettings,
                child: const Text('LƯU THAY ĐỔI', style: TextStyle(fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReadOnlyField(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 13)),
        const SizedBox(height: 4),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Text(value, style: const TextStyle(fontSize: 15, color: Colors.black54)),
        ),
      ],
    );
  }
}