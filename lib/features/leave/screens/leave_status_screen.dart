import 'package:flutter/material.dart';

class LeaveStatusScreen extends StatelessWidget {
  final List<Map<String, dynamic>> leaveStatusList;

  const LeaveStatusScreen({super.key, required this.leaveStatusList});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text('Leave Status Details'),
        backgroundColor: const Color(0xFF2A5CAA),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16.0),
        itemCount: leaveStatusList.length,
        itemBuilder: (context, index) {
          final item = leaveStatusList[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item['title'] ?? '',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1E293B),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          item['category'] ?? 'Nghỉ có lương',
                          style: const TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2A5CAA).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      item['value'] ?? '0 Days',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2A5CAA),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}