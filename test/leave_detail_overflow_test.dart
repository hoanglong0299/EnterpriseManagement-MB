import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:enterprise_management/features/leave/widgets/leave_ui.dart';
import 'package:enterprise_management/models/leave_request.dart';

void main() {
  const sizes = [Size(320, 568), Size(360, 640), Size(393, 852), Size(412, 915), Size(600, 960)];
  const scales = [1.0, 1.3, 1.6, 2.0];

  for (final size in sizes) {
    for (final scale in scales) {
      testWidgets('Bảng chi tiết đơn nghỉ không tràn ở ${size.width.toInt()}x${size.height.toInt()}, chữ x$scale', (tester) async {
        tester.view.physicalSize = size * 3;
        tester.view.devicePixelRatio = 3;
        addTearDown(tester.view.reset);

        await tester.pumpWidget(
          MaterialApp(
            home: MediaQuery(
              data: MediaQueryData(size: size, textScaler: TextScaler.linear(scale)),
              child: Scaffold(body: Builder(
                builder: (ctx) => TextButton(
                  onPressed: () => showLeaveDetail(
                    ctx,
                    LeaveRequest(
                      id: 1,
                      employeeCode: 'NV0001',
                      employeeName: 'Nguyễn Thị Hoàng Phương Thảo Anh Minh',
                      leaveTypeCode: 'ANNUAL',
                      leaveTypeName: 'Nghỉ có phép theo chế độ của công ty',
                      startDate: DateTime(2026, 10, 20),
                      endDate: DateTime(2026, 10, 22),
                      unit: 'Days',
                      totalTime: 3,
                      reason: 'Lý do rất dài để kiểm tra việc xuống dòng trong bảng chi tiết trên màn hình nhỏ',
                      status: 'Approved',
                      approverName: 'Trần Văn Quản Lý Phòng Ban Rất Dài',
                      approvedAt: DateTime(2026, 10, 15, 9, 30),
                    ),
                    showEmployee: true,
                  ),
                  child: const Text('mở'),
                ),
              )),
            ),
          ),
        );
        await tester.tap(find.text('mở'));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      });
    }
  }
}
