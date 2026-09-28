import 'package:flutter/material.dart';
import '../../check_in/screens/check_in_screen.dart';
import '../../calender/screens/calendar_screen.dart'; // Đã thêm dấu chấm phẩy ở đây

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    // 1. Khai báo danh sách các màn hình tương ứng với 4 tab
    final List<Widget> screens = [
      _buildHomeBody(), // Index 0: Tab Home (Nội dung cũ)
      const Center(child: Text('Activity Screen')), // Index 1: Tab Activity
      const CalendarScreen(), // Index 2: Tab Calendar
      const Center(child: Text('Me Screen')), // Index 3: Tab Me
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: SafeArea(
        // 2. Nội dung thay đổi động dựa vào biến _currentIndex
        child: screens[_currentIndex],
      ),

      // Thanh Bottom Navigation Bar
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        type: BottomNavigationBarType.fixed,
        selectedItemColor: const Color(0xFF2A5CAA),
        unselectedItemColor: Colors.grey,
        items: [
          BottomNavigationBarColor(icon: const Icon(Icons.home_outlined), activeIcon: const Icon(Icons.home), label: 'Home'),
          BottomNavigationBarColor(icon: const Icon(Icons.assignment_outlined), activeIcon: const Icon(Icons.assignment), label: 'Activity'),
          BottomNavigationBarColor(icon: const Icon(Icons.calendar_month_outlined), activeIcon: const Icon(Icons.calendar_month), label: 'Calendar'),
          BottomNavigationBarColor(icon: const Icon(Icons.person_outline), activeIcon: const Icon(Icons.person), label: 'Me'),
        ],
      ),
    );
  }

  // --- HÀM TÁCH GIAO DIỆN HOME CŨ ---
  Widget _buildHomeBody() {
    return SingleChildScrollView(
      child: Column(
        children: [
          // 1. Header (Appbar tùy chỉnh với Thanh tìm kiếm & Avatar)
          _buildHeader(),

          // 2. Lưới nút bấm Menu chức năng (Quick Actions)
          _buildQuickMenu(context),

          const SizedBox(height: 10),

          // 3. Thẻ "Leave Status" (Trạng thái nghỉ phép)
          _buildCard(
            title: 'Leave Status',
            child: Column(
              children: [
                _buildStatusRow('Annual Leave', '7 Days'),
                const Divider(height: 1),
                _buildStatusRow('Sick Leave', '12 Days'),
                const Divider(height: 1),
                _buildStatusRow('Extended Child Care Leave', '0 Day'),
              ],
            ),
          ),

          // 4. Thẻ "Company Notice" (Thông báo công ty)
          _buildCard(
            title: 'Company Notice',
            child: const Padding(
              padding: EdgeInsets.symmetric(vertical: 8.0),
              child: Text(
                'Mobile Apps on Google Play and Apple AppStore. Search for "EMS Service".',
                style: TextStyle(color: Colors.black87, fontSize: 13),
              ),
            ),
          ),

          // 5. Thẻ "Useful Link" (Liên kết hữu ích)
          _buildCard(
            title: 'Useful Link',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                InkWell(
                  onTap: () {},
                  child: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8.0),
                    child: Text(
                      'EMS Service Website',
                      style: TextStyle(color: Colors.black54, fontSize: 13),
                    ),
                  ),
                ),
                const Divider(height: 1),
                InkWell(
                  onTap: () {},
                  child: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8.0),
                    child: Text(
                      'Insurance Policy',
                      style: TextStyle(color: Colors.black54, fontSize: 13),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),
        ],
      ),
    );
  }

  // --- WIDGET HEADERS ---
  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      color: const Color(0xFF2A5CAA),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.search, color: Colors.white, size: 26),
            onPressed: () {},
          ),
          const Spacer(),
          const Text(
            'Nguyễn Văn A',
            style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(width: 12),
          const CircleAvatar(
            radius: 18,
            backgroundColor: Colors.white24,
            child: Icon(Icons.person, color: Colors.white),
          ),
        ],
      ),
    );
  }

  // --- WIDGET GRID MENU (6 NÚT CHỨC NĂNG) ---
  Widget _buildQuickMenu(BuildContext context) {
    final List<Map<String, dynamic>> menuItems = [
      {'title': 'Leave Record', 'icon': Icons.flight_takeoff, 'color': const Color(0xFF2FA2B1), 'onTap': null},
      {'title': 'Claim Record', 'icon': Icons.receipt_long, 'color': const Color(0xFFD9534F), 'onTap': null},
      {
        'title': 'Clock In/Out',
        'icon': Icons.location_on,
        'color': const Color(0xFFE69D35),
        'onTap': () {
          // Navigating sang màn hình Chấm công
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const CheckInScreen()),
          );
        }
      },
      {'title': 'Payslip', 'icon': Icons.account_balance_wallet, 'color': const Color(0xFF43A047), 'onTap': null},
      {'title': 'Sp. Allow Record', 'icon': Icons.card_giftcard, 'color': const Color(0xFF3F51B5), 'onTap': null},
      {'title': 'More', 'icon': Icons.grid_view, 'color': const Color(0xFF607D8B), 'onTap': null},
    ];

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          childAspectRatio: 1.1,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
        ),
        itemCount: menuItems.length,
        itemBuilder: (context, index) {
          final item = menuItems[index];
          return InkWell(
            onTap: () {
              if (item['onTap'] != null) {
                item['onTap']();
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Chức năng ${item['title']} đang phát triển')),
                );
              }
            },
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: item['color'] as Color,
                  child: Icon(item['icon'] as IconData, color: Colors.white, size: 22),
                ),
                const SizedBox(height: 8),
                Text(
                  item['title'] as String,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Colors.black87),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // --- WIDGET KHUNG THẺ KHỐI DƯỚI ---
  Widget _buildCard({required String title, required Widget child}) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.black12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
              ),
              const Icon(Icons.double_arrow, size: 16, color: Color(0xFF2A5CAA)),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  // --- HELPER DÒNG TRẠNG THÁI NGHỈ PHÉP ---
  Widget _buildStatusRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.black87, fontSize: 13)),
          Row(
            children: [
              Text(value, style: const TextStyle(color: Colors.black54, fontSize: 13)),
              const SizedBox(width: 4),
              const Icon(Icons.chevron_right, size: 18, color: Colors.grey),
            ],
          ),
        ],
      ),
    );
  }
}

// Custom Helper Class cho Bottom Navigation
class BottomNavigationBarColor extends BottomNavigationBarItem {
  BottomNavigationBarColor({
    required super.icon,
    required super.activeIcon,
    required super.label,
  });
}