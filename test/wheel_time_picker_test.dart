import 'package:enterprise_management/shared/widgets/wheel_time_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _app(ValueNotifier<TimeOfDay?> result, TimeOfDay initial, {double textScale = 1.0, Size? size}) {
  return MaterialApp(
    home: MediaQuery(
      data: MediaQueryData(size: size ?? const Size(400, 800), textScaler: TextScaler.linear(textScale)),
      child: Builder(
        builder: (context) => Scaffold(
          body: Center(
            child: ElevatedButton(
              onPressed: () async => result.value = await showWheelTimePicker(context, initial: initial, title: 'Giờ vào đề xuất'),
              child: const Text('mở'),
            ),
          ),
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('cuộn bánh xe đổi giờ và bấm Xong trả về giờ mới', (tester) async {
    final result = ValueNotifier<TimeOfDay?>(null);
    await tester.pumpWidget(_app(result, const TimeOfDay(hour: 8, minute: 0)));

    await tester.tap(find.text('mở'));
    await tester.pumpAndSettle();
    expect(find.text('Giờ vào đề xuất'), findsOneWidget);

    // Kéo bánh xe giờ (bên trái) lên: giờ tăng lên so với 8.
    await tester.drag(find.byType(CupertinoPicker).first, const Offset(0, -64));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Xong'));
    await tester.pumpAndSettle();

    expect(result.value, isNotNull);
    expect(result.value!.hour, isNot(8));
  });

  testWidgets('bấm Huỷ thì không trả về giờ', (tester) async {
    final result = ValueNotifier<TimeOfDay?>(null);
    await tester.pumpWidget(_app(result, const TimeOfDay(hour: 17, minute: 30)));

    await tester.tap(find.text('mở'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Huỷ'));
    await tester.pumpAndSettle();

    expect(result.value, isNull);
  });

  testWidgets('bấm Xong khi chưa cuộn trả về đúng giờ ban đầu', (tester) async {
    final result = ValueNotifier<TimeOfDay?>(null);
    await tester.pumpWidget(_app(result, const TimeOfDay(hour: 17, minute: 30)));

    await tester.tap(find.text('mở'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Xong'));
    await tester.pumpAndSettle();

    expect(result.value, const TimeOfDay(hour: 17, minute: 30));
  });

  for (final size in const [Size(320, 568), Size(360, 640), Size(412, 915)]) {
    for (final scale in const [1.0, 1.6, 2.0]) {
      testWidgets('bộ chọn giờ không tràn ở ${size.width.toInt()}x${size.height.toInt()}, chữ x$scale', (tester) async {
        tester.view.physicalSize = size * 3;
        tester.view.devicePixelRatio = 3;
        addTearDown(tester.view.reset);

        final result = ValueNotifier<TimeOfDay?>(null);
        await tester.pumpWidget(_app(result, const TimeOfDay(hour: 8, minute: 0), textScale: scale, size: size));
        await tester.tap(find.text('mở'));
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
      });
    }
  }
}
