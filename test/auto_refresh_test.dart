import 'package:enterprise_management/services/live_updates.dart';
import 'package:enterprise_management/shared/widgets/auto_refresh.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late LiveUpdates live;

  setUp(() {
    live = LiveUpdates(() async => const LivePollResult([]));
  });
  tearDown(() => live.dispose());

  Widget host(Future<void> Function() onRefresh, {Set<String>? types, Duration fallback = const Duration(seconds: 60)}) {
    return MaterialApp(
      home: AutoRefresh(source: live, onRefresh: onRefresh, types: types, fallback: fallback, child: const Text('x')),
    );
  }

  testWidgets('gọi onRefresh khi đúng loại, không gọi khi sai loại', (t) async {
    var calls = 0;
    await t.pumpWidget(host(() async => calls++, types: {NotificationTypes.leaveApproved}));
    live.notifyLocalChange('LeaveApproved');
    await t.pump();
    expect(calls, 1);
    live.notifyLocalChange('LeaveRejected');
    await t.pump();
    expect(calls, 1);
  });

  testWidgets('types bỏ trống = mọi loại', (t) async {
    var calls = 0;
    await t.pumpWidget(host(() async => calls++));
    live.notifyLocalChange('BatKy');
    await t.pump();
    expect(calls, 1);
  });

  testWidgets('không gọi chồng: sự kiện đến khi đang chạy thì chạy lại đúng một lần sau đó', (t) async {
    var calls = 0;
    var active = 0;
    var maxActive = 0;
    await t.pumpWidget(host(() async {
      calls++;
      active++;
      if (active > maxActive) maxActive = active;
      await Future<void>.delayed(const Duration(seconds: 1));
      active--;
    }));
    live.notifyLocalChange('A');
    live.notifyLocalChange('A');
    live.notifyLocalChange('A');
    await t.pump(const Duration(seconds: 5));
    expect(maxActive, 1);
    expect(calls, 2);
  });

  testWidgets('timer dự phòng gọi định kỳ', (t) async {
    var calls = 0;
    await t.pumpWidget(host(() async => calls++, fallback: const Duration(seconds: 30)));
    await t.pump(const Duration(seconds: 31));
    expect(calls, 1);
    await t.pump(const Duration(seconds: 30));
    expect(calls, 2);
  });

  testWidgets('không gọi sau dispose', (t) async {
    var calls = 0;
    await t.pumpWidget(host(() async => calls++, fallback: const Duration(seconds: 30)));
    await t.pumpWidget(const MaterialApp(home: SizedBox()));
    live.notifyLocalChange('A');
    await t.pump(const Duration(seconds: 100));
    expect(calls, 0);
  });

  testWidgets('quay lại foreground thì gọi lại', (t) async {
    var calls = 0;
    await t.pumpWidget(host(() async => calls++));
    t.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    t.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await t.pump();
    expect(calls, 1);
  });
}
