import 'package:enterprise_management/features/home/widgets/home_header.dart';
import 'package:enterprise_management/shared/widgets/count_badge.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _header(int unread) => MaterialApp(
      home: Scaffold(
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: HomeHeader(greeting: 'Chào buổi tối, Lan', subtitle: 'Chúc bạn một ngày hiệu quả', name: 'Hoàng Thị Lan', unread: unread, onBellTap: () {}),
        ),
      ),
    );

void main() {
  final bell = find.byIcon(Icons.notifications_none_rounded);

  for (final unread in [1, 5, 9, 10, 99, 250]) {
    testWidgets('chuông ở Trang chủ không xê dịch khi có $unread thông báo', (tester) async {
      await tester.pumpWidget(_header(0));
      final before = tester.getCenter(bell);
      final beforeSize = tester.getSize(bell);

      await tester.pumpWidget(_header(unread));
      expect(tester.getCenter(bell), before, reason: 'icon chuông phải đứng yên khi hiện chấm đỏ');
      expect(tester.getSize(bell), beforeSize);
      expect(find.text(unread > 9 ? '9+' : '$unread'), findsOneWidget);
    });
  }

  testWidgets('không có thông báo thì không hiện chấm đỏ', (tester) async {
    await tester.pumpWidget(_header(0));
    expect(find.byType(CountBadge), findsOneWidget);
    expect(find.text('0'), findsNothing);
  });

  testWidgets('chuông đứng yên cả khi chữ hệ thống phóng to', (tester) async {
    Widget scaled(int unread) => MediaQuery(
          data: const MediaQueryData(textScaler: TextScaler.linear(2.0), size: Size(360, 640)),
          child: _header(unread),
        );
    await tester.pumpWidget(scaled(0));
    final before = tester.getCenter(bell);
    await tester.pumpWidget(scaled(7));
    expect(tester.getCenter(bell), before);
    expect(tester.takeException(), isNull);
  });

  testWidgets('đối chứng: kiểu Badge cũ trong ô 44x44 BỊ xê dịch (test này phải bắt được lỗi)', (tester) async {
    Widget old(int unread) => MaterialApp(
          home: Scaffold(
            body: Align(
              alignment: Alignment.topLeft,
              child: Container(
                width: 44,
                height: 44,
                child: Badge(
                  isLabelVisible: unread > 0,
                  label: Text('$unread'),
                  child: const Icon(Icons.notifications_none_rounded),
                ),
              ),
            ),
          ),
        );
    await tester.pumpWidget(old(0));
    final before = tester.getCenter(find.byIcon(Icons.notifications_none_rounded));
    await tester.pumpWidget(old(5));
    final after = tester.getCenter(find.byIcon(Icons.notifications_none_rounded));
    expect(after, isNot(before));
  });
}
