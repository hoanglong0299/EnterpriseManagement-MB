import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../providers/check_in_provider.dart';

class CheckInScreen extends StatefulWidget {
  const CheckInScreen({super.key});

  @override
  State<CheckInScreen> createState() => _CheckInScreenState();
}

class _CheckInScreenState extends State<CheckInScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CheckInProvider>().determinePosition();
    });
  }

  void _handleAction(String type) async {
    final provider = context.read<CheckInProvider>();
    final success = await provider.performAction(type);
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(provider.statusMessage),
          backgroundColor: success ? Colors.green : Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CheckInProvider>();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFF2A5CAA),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {},
        ),
        title: const Text(
          'Clock In/Out',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.normal),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 30),
              
              // 1. Khối Đồng hồ
              Center(
                child: Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFF2A5CAA),
                    border: Border.all(color: const Color(0xFFD6E4F5), width: 12),
                  ),
                  child: StreamBuilder(
                    stream: Stream.periodic(const Duration(seconds: 1)),
                    builder: (context, snapshot) {
                      final now = DateTime.now();
                      return Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            DateFormat('EEEE').format(now),
                            style: const TextStyle(color: Colors.white70, fontSize: 16),
                          ),
                          Text(
                            DateFormat('HH:mm').format(now),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 48,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            DateFormat('MMMM dd, yyyy').format(now),
                            style: const TextStyle(color: Colors.white70, fontSize: 14),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),
              
              const SizedBox(height: 30),

              // 2. Khối Vị trí & Địa chỉ
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.location_on, color: Color(0xFF2A5CAA), size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Văn phòng Công ty',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          provider.currentAddress,
                          style: const TextStyle(color: Colors.black87, fontSize: 14),
                        ),
                        if (provider.currentPosition != null)
                          Text(
                            '(${provider.currentPosition!.latitude.toStringAsFixed(6)} , ${provider.currentPosition!.longitude.toStringAsFixed(6)})',
                            style: const TextStyle(color: Colors.black54, fontSize: 12),
                          ),
                        const SizedBox(height: 8),
                        Text(
                          provider.statusMessage,
                          style: TextStyle(
                            color: provider.canCheckIn ? Colors.green : Colors.red,
                            fontWeight: FontWeight.bold,
                            fontSize: 12
                          ),
                        )
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => provider.determinePosition(),
                    icon: const Icon(Icons.refresh, color: Colors.grey),
                  )
                ],
              ),
              
              const SizedBox(height: 24),

              // 3. Khối Nút Bấm Clock In / Out
              ElevatedButton(
                onPressed: provider.canCheckIn ? () => _handleAction('CLOCK IN') : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2A5CAA),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                ),
                child: const Text('CLOCK IN', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ),
              const SizedBox(height: 16),
              OutlinedButton(
                onPressed: provider.canCheckIn ? () => _handleAction('CLOCK OUT') : null,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  side: const BorderSide(color: Colors.grey, width: 1.5),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                ),
                child: const Text('CLOCK OUT', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 16)),
              ),

              const SizedBox(height: 32),
              const Divider(thickness: 1, color: Colors.black12),
              const SizedBox(height: 16),

              // 4. Khối Lịch sử (Fake data giống ảnh mẫu)
              const Text(
                'History',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                DateFormat('EEEE, MMMM dd, yyyy').format(DateTime.now().subtract(const Duration(days: 1))),
                style: const TextStyle(color: Colors.grey, fontSize: 14),
              ),
              const SizedBox(height: 12),
              
              _buildHistoryItem('17.50 at Văn phòng Công ty (OUT)'),
              const SizedBox(height: 16),
              _buildHistoryItem('08.35 at Văn phòng Công ty (IN)'),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  // Widget con hiển thị từng dòng lịch sử
  Widget _buildHistoryItem(String title) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: Colors.grey, width: 2),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: const TextStyle(color: Colors.grey, fontSize: 14),
        ),
      ],
    );
  }
}