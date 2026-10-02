import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../check_in/screens/check_in_screen.dart';
import '../../calendar/screens/calendar_screen.dart';
import '../../activity/screens/activity_screen.dart';
import '../../leave/providers/leave_provider.dart';
import '../../profile/providers/profile_provider.dart';
import '../../profile/screens/profile_screen.dart';
import '../../leave/screens/leave_record_screen.dart';
import '../../leave/screens/leave_status_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    // Dashboard la man hinh dau tien sau khi dang nhap: tai ho so va so du nghi phep that tai day.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProfileProvider>().load();
      context.read<LeaveProvider>().load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> screens = [
      _buildHomeBody(), 
      const ActivityScreen(), 
      const CalendarScreen(), 
      const ProfileScreen(), 
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: SafeArea(
        child: screens[_currentIndex],
      ),
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

  // --- HÀM TÁCH GIAO DIỆN HOME ---
  Widget _buildHomeBody() {
    final leaveStatusData = context.watch<LeaveProvider>().leaveStatusList;

    return SingleChildScrollView(
      child: Column(
        children: [
          _buildHeader(),
          _buildQuickMenu(context),
          const SizedBox(height: 10),

          // 3. Thẻ "Leave Status" (Giữ nguyên khung tổng hợp bên ngoài)
          // Khi bấm vào thẻ hoặc nút mũi tên sẽ chuyển sang màn hình danh sách chi tiết
          InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => LeaveStatusScreen(leaveStatusList: leaveStatusData),
                ),
              );
            },
            child: AbsorbPointer(
              // Dùng AbsorbPointer để giữ nguyên giao diện hiển thị khung thẻ thu gọn nhưng vẫn bắt sự kiện InkWell tổng
              child: _buildCard(
                title: 'Leave Status',
                child: Column(
                  children: [
                    // Hiển thị tối đa 3 mục tiêu biểu ngoài Dashboard
                    for (var i = 0; i < leaveStatusData.length && i < 3; i++) ...[
                      if (i > 0) const Divider(height: 1),
                      _buildStatusRow(leaveStatusData[i]['title'], leaveStatusData[i]['value']),
                    ],
                  ],
                ),
              ),
            ),
          ),

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

          _buildCard(
            title: 'Useful Link',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                InkWell(
                  onTap: () {},
                  child: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8.0),
                    child: Text('EMS Service Website', style: TextStyle(color: Colors.black54, fontSize: 13)),
                  ),
                ),
                const Divider(height: 1),
                InkWell(
                  onTap: () {},
                  child: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8.0),
                    child: Text('Insurance Policy', style: TextStyle(color: Colors.black54, fontSize: 13)),
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
          Text(
            context.watch<ProfileProvider>().displayName,
            style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
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

  Widget _buildQuickMenu(BuildContext context) {
    final List<Map<String, dynamic>> menuItems = [
      {
        'title': 'Leave Record', 
        'icon': Icons.flight_takeoff, 
        'color': const Color(0xFF2FA2B1), 
        'onTap': () async {
          // Chuyển hướng sang LeaveRecordScreen và có thể nhận dữ liệu cập nhật ngày nghỉ nếu cần
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const LeaveRecordScreen()),
          );
        }
      },
      {
        'title': 'Clock In/Out',
        'icon': Icons.location_on,
        'color': const Color(0xFFE69D35),
        'onTap': () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const CheckInScreen()),
          );
        }
      },
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

class BottomNavigationBarColor extends BottomNavigationBarItem {
  BottomNavigationBarColor({
    required super.icon,
    required super.activeIcon,
    required super.label,
  });
}