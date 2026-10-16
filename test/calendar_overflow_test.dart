import 'package:enterprise_management/features/calendar/widgets/attendance_day_cell.dart';
import 'package:enterprise_management/features/calendar/widgets/month_year_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const sizes = [Size(320, 568), Size(360, 640), Size(393, 852), Size(412, 915), Size(600, 960)];
  const scales = [1.0, 1.3, 1.6, 2.0];

  for (final size in sizes) {
    for (final scale in scales) {
      testWidgets('Lịch không tràn ở ${size.width.toInt()}x${size.height.toInt()}, chữ x$scale', (tester) async {
        tester.view.physicalSize = size * 3;
        tester.view.devicePixelRatio = 3;
        addTearDown(tester.view.reset);

        await tester.pumpWidget(
          MaterialApp(
            home: MediaQuery(
              data: MediaQueryData(size: size, textScaler: TextScaler.linear(scale)),
              child: Scaffold(
                body: Builder(
                  builder: (context) => SingleChildScrollView(
                    child: Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: 35,
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 7, mainAxisExtent: 52),
                            itemBuilder: (_, i) => AttendanceDayCell(
                              day: DateTime(2026, 10, i % 28 + 1),
                              attendance: const DayAttendance(DayPartStatus.onTime, DayPartStatus.late),
                              isToday: i == 3,
                              isSelected: i == 4,
                            ),
                          ),
                        ),
                        TextButton(onPressed: () => showMonthYearPicker(context, DateTime(2026, 10, 1)), child: const Text('mở')),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
        expect(tester.takeException(), isNull);

        // Mở bảng chọn tháng/năm rồi chuyển sang lưới năm.
        await tester.tap(find.text('mở'));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        await tester.tap(find.text('2026'));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      });
    }
  }
}
