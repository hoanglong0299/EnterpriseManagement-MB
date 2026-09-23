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
  
  // Gọi hàm xử lý và hiển thị thông báo
  void _handleAction(String type) async {
    final provider = context.read<CheckInProvider>();
    await provider.performAction(type);
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$type thành công!'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
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
          onPressed: () => Navigator.pop(context),
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
              
              // 1. KHỐI ĐỒNG HỒ ĐIỆN TỬ
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

              // 2. KHỐI VỊ TRÍ (Hardcode theo mẫu)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.location_on, color: Color(0xFF2A5CAA), size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          'Singapore Office',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        SizedBox(height: 4),
                        Text(
                          '160-168 Robinson Rd, Singapore\n(1.277581 , 103.848053)',
                          style: TextStyle(color: Colors.black87, fontSize: 14, height: 1.4),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 24),

              // 3. NÚT CLOCK IN (Xanh) - Khóa khi đã Clock In
              ElevatedButton(
                onPressed: (!provider.isLoading && !provider.hasClockedIn) 
                    ? () => _handleAction('CLOCK IN') 
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2A5CAA),
                  disabledBackgroundColor: Colors.grey.shade300,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                ),
                child: (provider.isLoading && !provider.hasClockedIn)
                    ? const SizedBox(
                        height: 20, width: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : const Text(
                        'CLOCK IN', 
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                      ),
              ),
              
              const SizedBox(height: 12),
              
              // 4. NÚT CLOCK OUT (Trắng viền) - Khóa khi chưa Clock In
              OutlinedButton(
                onPressed: (!provider.isLoading && provider.hasClockedIn) 
                    ? () => _handleAction('CLOCK OUT') 
                    : null,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  side: BorderSide(
                    color: provider.hasClockedIn ? const Color(0xFF2A5CAA) : Colors.grey.shade300, 
                    width: 1.5
                  ),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                ),
                child: (provider.isLoading && provider.hasClockedIn)
                    ? const SizedBox(
                        height: 20, width: 20,
                        child: CircularProgressIndicator(color: Color(0xFF2A5CAA), strokeWidth: 2),
                      )
                    : Text(
                        'CLOCK OUT', 
                        style: TextStyle(
                          color: provider.hasClockedIn ? Colors.black87 : Colors.grey, 
                          fontWeight: FontWeight.bold, 
                          fontSize: 16,
                        ),
                      ),
              ),

              const SizedBox(height: 32),
              const Divider(thickness: 1, color: Colors.black12),
              const SizedBox(height: 16),

              // 5. KHỐI LỊCH SỬ CHẤM CÔNG
              const Text(
                'History',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                DateFormat('EEEE, MMMM dd, yyyy').format(DateTime.now()),
                style: const TextStyle(color: Colors.grey, fontSize: 14),
              ),
              const SizedBox(height: 12),
              
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: provider.historyRecords.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16.0),
                    child: Row(
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
                          provider.historyRecords[index],
                          style: const TextStyle(color: Colors.grey, fontSize: 14),
                        ),
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }
}