import 'package:enterprise_management/core/utils/punch_lock.dart';
import 'package:enterprise_management/features/home/widgets/check_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _button({required bool locked, required VoidCallback onPressed, bool checkedIn = false}) =>
    MaterialApp(home: Scaffold(body: Center(child: CheckButton(checkedIn: checkedIn, loading: false, onPressed: onPressed, locked: locked))));

void main() {
  group('isPunchLocked', () {
    for (final c in const [
      (7, 45, false),
      (17, 0, false),
      (17, 59, false),
      (18, 0, true),
      (18, 1, true),
      (23, 59, true),
    ]) {
      test('lúc ${c.$1}:${c.$2} thì khoá = ${c.$3}', () {
        expect(isPunchLocked(DateTime(2026, 10, 19, c.$1, c.$2)), c.$3);
      });
    }
  });

  testWidgets('chưa khoá: bấm được và hiện "Chấm công vào"', (tester) async {
    var taps = 0;
    await tester.pumpWidget(_button(locked: false, onPressed: () => taps++));
    expect(find.text('Chấm công vào'), findsOneWidget);
    await tester.tap(find.text('Chấm công vào'));
    expect(taps, 1);
  });

  testWidgets('đã khoá: hiện "Đã khoá", không bấm được cả khi đã chấm công vào', (tester) async {
    var taps = 0;
    await tester.pumpWidget(_button(locked: true, checkedIn: true, onPressed: () => taps++));
    expect(find.text('Đã khoá'), findsOneWidget);
    expect(find.text('Chấm công ra'), findsNothing);
    expect(find.byIcon(Icons.lock_outline_rounded), findsOneWidget);
    await tester.tap(find.text('Đã khoá'));
    expect(taps, 0);
  });
}
