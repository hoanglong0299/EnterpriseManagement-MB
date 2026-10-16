import 'package:enterprise_management/features/home/widgets/check_button.dart';
import 'package:enterprise_management/features/home/widgets/home_header.dart';
import 'package:enterprise_management/features/home/widgets/work_summary_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const sizes = [Size(320, 568), Size(360, 640), Size(393, 852), Size(412, 915), Size(600, 960)];
  const scales = [1.0, 1.3, 1.6, 2.0];

  for (final size in sizes) {
    for (final scale in scales) {
      testWidgets('Trang chủ không tràn ở ${size.width.toInt()}x${size.height.toInt()}, chữ x$scale', (tester) async {
        tester.view.physicalSize = size * 3;
        tester.view.devicePixelRatio = 3;
        addTearDown(tester.view.reset);

        await tester.pumpWidget(
          MaterialApp(
            home: MediaQuery(
              data: MediaQueryData(size: size, textScaler: TextScaler.linear(scale)),
              child: Scaffold(
                body: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                  children: [
                    HomeHeader(
                      greeting: 'Chào buổi chiều, Quốc',
                      subtitle: 'Chúc bạn một ngày hiệu quả',
                      name: 'Đặng Văn Quốc',
                      unread: 12,
                      onBellTap: () {},
                    ),
                    const SizedBox(height: 16),
                    const WorkSummaryCard(record: null),
                    const SizedBox(height: 12),
                    Center(child: CheckButton(checkedIn: false, loading: false, onPressed: () {})),
                    Center(child: CheckButton(checkedIn: true, loading: false, onPressed: () {})),
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
