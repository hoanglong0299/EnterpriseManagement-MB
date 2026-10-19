import 'package:enterprise_management/features/overtime/widgets/overtime_ui.dart';
import 'package:enterprise_management/models/overtime.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const sizes = [Size(320, 568), Size(360, 640), Size(393, 852), Size(412, 915), Size(600, 960)];
  const scales = [1.0, 1.3, 1.6, 2.0];

  final request = OvertimeRequest(
    id: 1,
    employeeCode: 'NV0001',
    employeeName: 'Nguyễn Thị Hoàng Phương Thảo Anh Minh',
    date: DateTime(2026, 10, 22),
    startTime: '17:00',
    endTime: '19:30',
    minutes: 150,
    reason: 'Lý do rất dài để kiểm tra việc xuống dòng trong thẻ đơn làm thêm giờ trên màn hình nhỏ',
    status: 'Rejected',
    approverName: 'Trần Văn Quản Lý Phòng Ban Rất Dài',
    rejectionReason: 'Lý do từ chối cũng khá dài để thử xuống dòng',
    createdAt: DateTime(2026, 10, 19, 12),
  );

  for (final size in sizes) {
    for (final scale in scales) {
      testWidgets('Thẻ đơn làm thêm giờ không tràn ở ${size.width.toInt()}x${size.height.toInt()}, chữ x$scale', (tester) async {
        tester.view.physicalSize = size * 3;
        tester.view.devicePixelRatio = 3;
        addTearDown(tester.view.reset);

        await tester.pumpWidget(
          MaterialApp(
            home: MediaQuery(
              data: MediaQueryData(size: size, textScaler: TextScaler.linear(scale)),
              child: Scaffold(
                body: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    OvertimeCard(request: request, showEmployee: true),
                    OvertimeCard(
                      request: request,
                      actions: Row(
                        children: [
                          Expanded(child: OutlinedButton(onPressed: () {}, child: const Text('TỪ CHỐI'))),
                          const SizedBox(width: 12),
                          Expanded(child: ElevatedButton(onPressed: () {}, child: const Text('DUYỆT'))),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );

        expect(tester.takeException(), isNull);
      });
    }
  }
}
