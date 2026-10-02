import 'package:flutter/material.dart';

class ActivityScreen extends StatefulWidget {
  const ActivityScreen({super.key});

  @override
  State<ActivityScreen> createState() => _ActivityScreenState();
}

class _ActivityScreenState extends State<ActivityScreen> {
  // Hardcode danh sách thông báo
  final List<Map<String, dynamic>> _inboxItems = [
    {
      'name': 'Justin James',
      'action': 'has submitted a leave application for approval',
      'type': 'Leave',
      'time': '28/09/2023 (Thu) 16:09',
      'isRead': false,
    },
    {
      'name': 'Justin James',
      'action': 'has submitted a leave application for approval',
      'type': 'Leave',
      'time': '25/09/2023 (Mon) 10:32',
      'isRead': false,
    },
    {
      'name': 'Justin James',
      'action': 'has submitted an OT application for approval',
      'type': 'OT',
      'time': '22/09/2023 (Fri) 17:54',
      'isRead': false,
    },
    {
      'name': 'Wayne Lim',
      'action': 'An OT authorisation for Wayne Lim has been approved by Wanda Ong',
      'type': 'OT',
      'time': '22/09/2023 (Fri) 17:53',
      'isRead': true,
    },
    {
      'name': 'Wayne Lim',
      'action': 'An OT authorisation for Wayne Lim has been approved by Wanda Ong',
      'type': 'OT',
      'time': '22/09/2023 (Fri) 17:52',
      'isRead': true,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          title: const Text(
            'Activity',
            style: TextStyle(
              color: Color(0xFF2A5CAA),
              fontWeight: FontWeight.bold,
            ),
          ),
          centerTitle: true,
          bottom: const TabBar(
            labelColor: Color(0xFF2A5CAA),
            unselectedLabelColor: Colors.grey,
            indicatorColor: Color(0xFF2A5CAA),
            indicatorWeight: 3,
            tabs: [
              Tab(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Tasks'),
                    SizedBox(width: 8),
                    CircleAvatar(
                      radius: 12,
                      backgroundColor: Color(0xFF2A5CAA),
                      child: Text('0', style: TextStyle(color: Colors.white, fontSize: 12)),
                    ),
                  ],
                ),
              ),
              Tab(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Inbox'),
                    SizedBox(width: 8),
                    CircleAvatar(
                      radius: 12,
                      backgroundColor: Color(0xFF2A5CAA),
                      child: Text('2', style: TextStyle(color: Colors.white, fontSize: 12)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // Tab Tasks (hiện tại để trống)
            const Center(
              child: Text('No tasks available', style: TextStyle(color: Colors.grey)),
            ),
            
            // Tab Inbox
            Column(
              children: [
                // Toolbar (Đánh dấu đã đọc, Lọc)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.mark_email_read_outlined, color: Color(0xFF2A5CAA)),
                        onPressed: () {},
                      ),
                      IconButton(
                        icon: const Icon(Icons.filter_alt_outlined, color: Color(0xFF2A5CAA)),
                        onPressed: () {},
                      ),
                    ],
                  ),
                ),
                
                // Danh sách thông báo
                Expanded(
                  child: ListView.separated(
                    itemCount: _inboxItems.length,
                    separatorBuilder: (context, index) => const Divider(height: 1, color: Colors.black12),
                    itemBuilder: (context, index) {
                      final item = _inboxItems[index];
                      return _buildNotificationItem(item);
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationItem(Map<String, dynamic> item) {
    Color typeColor = item['type'] == 'Leave' ? const Color(0xFF8CC63F) : const Color(0xFFD9534F);

    return Container(
      color: item['isRead'] ? const Color(0xFFF5F7FA) : Colors.white,
      padding: const EdgeInsets.all(16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Avatar
          const CircleAvatar(
            radius: 24,
            backgroundColor: Colors.grey,
            child: Icon(Icons.person, color: Colors.white),
          ),
          const SizedBox(width: 16),
          
          // Nội dung
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RichText(
                  text: TextSpan(
                    style: const TextStyle(color: Colors.black87, fontSize: 14, height: 1.4),
                    children: [
                      if (!item['action'].toString().startsWith('An OT'))
                        TextSpan(
                          text: '${item['name']} ',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      TextSpan(text: item['action']),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: typeColor,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        item['type'],
                        style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      item['time'],
                      style: const TextStyle(color: Colors.grey, fontSize: 13),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}