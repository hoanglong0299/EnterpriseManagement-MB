import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:enterprise_management/features/leave/widgets/leave_return_ui.dart';
import 'package:enterprise_management/features/leave/widgets/leave_ui.dart';
import 'package:enterprise_management/models/attendance_hr.dart';

LeaveReturnRequest _request() => LeaveReturnRequest(
      id: 1,
      employeeCode: 'NV0001',
      employeeName: 'Nguyễn Thị Hoàng Phương Thảo Anh Minh',
      fromDate: DateTime(2026, 10, 20),
      fromSession: 'Morning',
      reason: 'Đã giải quyết xong việc gia đình nên xin đi làm lại sớm hơn dự kiến để hỗ trợ đồng nghiệp',
      status: 'PendingManager',
      rejectionReason: 'Không phù hợp kế hoạch nhân sự của phòng trong tuần này',
      managerName: 'Trần Văn Quản Lý Phòng Ban Rất Dài',
      processedByName: 'Lê Thị Nhân Sự Xử Lý',
      createdAt: DateTime(2026, 10, 14),
      sessions: [
        for (var i = 0; i < 3; i++)
          LeaveReturnSession(
            date: DateTime(2026, 10, 20 + i),
            session: i.isEven ? 'Morning' : 'Afternoon',
            leaveRequestId: 1234 + i,
            leaveTypeName: 'Nghỉ phép năm',
            state: 'AwaitingHr',
            workedStatus: 'Late',
          ),
      ],
    );

void main() {
  const sizes = [Size(320, 568), Size(360, 640), Size(393, 852), Size(412, 915), Size(600, 960)];
  const scales = [1.0, 1.3, 1.6, 2.0];

  for (final size in sizes) {
    for (final scale in scales) {
      testWidgets('ReturnRequestCard + LeaveStatusFilterBar không tràn ở ${size.width.toInt()}x${size.height.toInt()}, chữ x$scale', (tester) async {
        tester.view.physicalSize = size * 3;
        tester.view.devicePixelRatio = 3;
        addTearDown(tester.view.reset);

        await tester.pumpWidget(
          MaterialApp(
            home: MediaQuery(
              data: MediaQueryData(size: size, textScaler: TextScaler.linear(scale)),
              child: Scaffold(body: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  LeaveStatusFilterBar(selected: null, onChanged: (_) {}),
                  ReturnRequestCard(
                    request: _request(),
                    showEmployee: true,
                    actions: Row(children: [
                      Expanded(child: OutlinedButton(onPressed: () {}, child: const Text('TỪ CHỐI'))),
                      const SizedBox(width: 12),
                      Expanded(child: ElevatedButton(onPressed: () {}, child: const Text('DUYỆT'))),
                    ]),
                  ),
                  ReturnRequestCard(request: _request()),
                ],
              )),
            ),
          ),
        );

        expect(tester.takeException(), isNull);
      });
    }
  }
}
