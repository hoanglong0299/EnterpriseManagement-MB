import 'package:enterprise_management/core/settings/text_size_provider.dart';
import 'package:enterprise_management/features/profile/widgets/text_size_section.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Dựng một app nhỏ giống cách app.dart áp cỡ chữ: builder nhân hệ số người dùng chọn lên cỡ chữ hệ thống.
Widget _app(TextSizeProvider provider, {double systemScale = 1.0, Size size = const Size(400, 800)}) {
  return ChangeNotifierProvider.value(
    value: provider,
    child: MediaQuery(
      data: MediaQueryData(size: size, textScaler: TextScaler.linear(systemScale)),
      child: MaterialApp(
        builder: (context, child) {
          final factor = context.watch<TextSizeProvider>().factor;
          final media = MediaQuery.of(context);
          return MediaQuery(
            data: media.copyWith(textScaler: TextScaler.linear(media.textScaler.scale(1.0) * factor)),
            child: child!,
          );
        },
        home: Scaffold(
          body: Builder(
            builder: (context) => ListView(children: [
              const TextSizeSection(),
              Text('${MediaQuery.of(context).textScaler.scale(10)}', key: const ValueKey('scaled')),
            ]),
          ),
        ),
      ),
    ),
  );
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('mặc định là cỡ chữ hiện tại (hệ số 1.0)', () async {
    final p = TextSizeProvider();
    await p.load();
    expect(p.option, TextSizeOption.normal);
    expect(p.factor, 1.0);
  });

  test('giá trị lưu không hợp lệ thì quay về mặc định', () async {
    SharedPreferences.setMockInitialValues({TextSizeProvider.prefsKey: 'khong-ton-tai'});
    final p = TextSizeProvider();
    await p.load();
    expect(p.option, TextSizeOption.normal);
  });

  test('chọn cỡ chữ được lưu và nhớ lại ở lần mở sau', () async {
    final first = TextSizeProvider();
    await first.select(TextSizeOption.large);
    expect(first.factor, 1.15);

    final second = TextSizeProvider();
    await second.load();
    expect(second.option, TextSizeOption.large);
  });

  testWidgets('chọn mức trong cài đặt đổi cỡ chữ của toàn app ngay lập tức', (tester) async {
    final p = TextSizeProvider();
    await tester.pumpWidget(_app(p));
    expect(find.byKey(const ValueKey('scaled')), findsOneWidget);
    expect(tester.widget<Text>(find.byKey(const ValueKey('scaled'))).data, '10.0');

    await tester.tap(find.text('Rất lớn'));
    await tester.pumpAndSettle();
    expect(p.option, TextSizeOption.extraLarge);
    expect(double.parse(tester.widget<Text>(find.byKey(const ValueKey('scaled'))).data!), closeTo(13.0, 0.001));

    await tester.tap(find.text('Mặc định'));
    await tester.pumpAndSettle();
    expect(tester.widget<Text>(find.byKey(const ValueKey('scaled'))).data, '10.0');
  });

  testWidgets('nhân thêm lên trên cỡ chữ hệ thống (hệ thống 1.3 x mức Lớn 1.15)', (tester) async {
    final p = TextSizeProvider();
    await p.select(TextSizeOption.large);
    await tester.pumpWidget(_app(p, systemScale: 1.3));
    expect(double.parse(tester.widget<Text>(find.byKey(const ValueKey('scaled'))).data!), closeTo(14.95, 0.001));
  });

  for (final size in const [Size(320, 568), Size(360, 640), Size(412, 915)]) {
    for (final option in TextSizeOption.values) {
      testWidgets('mục Cỡ chữ không tràn ở ${size.width.toInt()}x${size.height.toInt()}, mức ${option.label}', (tester) async {
        tester.view.physicalSize = size * 3;
        tester.view.devicePixelRatio = 3;
        addTearDown(tester.view.reset);
        final p = TextSizeProvider();
        await p.select(option);
        await tester.pumpWidget(_app(p, size: size, systemScale: 1.6));
        expect(tester.takeException(), isNull);
      });
    }
  }
}
