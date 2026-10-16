import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:enterprise_management/features/manager/screens/manager_dashboard_screen.dart';

void main() {
  const sizes = [Size(320, 568), Size(360, 640), Size(393, 852), Size(412, 915), Size(600, 960)];
  const scales = [1.0, 1.3, 1.6, 2.0];

  for (final size in sizes) {
    for (final scale in scales) {
      testWidgets('ManagerMetricGrid không tràn ở ${size.width.toInt()}x${size.height.toInt()}, chữ x$scale', (tester) async {
        tester.view.physicalSize = size * 3;
        tester.view.devicePixelRatio = 3;
        addTearDown(tester.view.reset);

        await tester.pumpWidget(
          MaterialApp(
            home: MediaQuery(
              data: MediaQueryData(size: size, textScaler: TextScaler.linear(scale)),
              child: Scaffold(body: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: ManagerMetricGrid(metrics: [
                  ManagerMetric('Quy mô team', 12, Icons.groups, Colors.indigo),
                  ManagerMetric('Có mặt hôm nay', 10, Icons.how_to_reg, Colors.green),
                  ManagerMetric('Nghỉ phép hôm nay', 1, Icons.beach_access, Colors.blue),
                  ManagerMetric('Đơn nghỉ chờ duyệt', 3, Icons.flight_takeoff, Colors.orange),
                  ManagerMetric('Chỉnh sửa công chờ duyệt', 100, Icons.edit_calendar, Colors.orange),
                ]),
              )),
            ),
          ),
        );

        expect(tester.takeException(), isNull);
      });
    }
  }
}
