import 'package:enterprise_management/models/app_notification.dart';
import 'package:enterprise_management/services/live_updates.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

AppNotification n(int id, [String type = 'LeaveApproved']) =>
    AppNotification(id: id, type: type, title: 'tb $id', body: '', isRead: false, createdAt: DateTime(2026));

void main() {
  late List<List<AppNotification>> script;
  late int calls;
  late LiveUpdates live;
  late List<AppNotification> got;

  setUp(() {
    script = [];
    calls = 0;
    got = [];
  });

  LiveUpdates make({GlobalKey<ScaffoldMessengerState>? key}) {
    final l = LiveUpdates(() async {
      final i = calls++;
      final items = script[i < script.length ? i : script.length - 1];
      return LivePollResult(items, unreadCount: items.length);
    }, messengerKey: key);
    l.events.listen(got.add);
    return l;
  }

  testWidgets('lần poll đầu không phát sự kiện, các lần sau phát đúng thông báo mới theo thứ tự, không phát lại', (t) async {
    script = [
      [n(5), n(4)],
      [n(7), n(6), n(5), n(4)],
      [n(7), n(6), n(5)],
    ];
    live = make();
    live.start();
    await t.pump();
    expect(got, isEmpty);

    await t.pump(const Duration(seconds: 10));
    expect(got.map((e) => e.id), [6, 7]);

    await t.pump(const Duration(seconds: 10));
    expect(got.map((e) => e.id), [6, 7]);
    live.dispose();
  });

  testWidgets('stop reset lastSeenId: start lại coi như lần đầu', (t) async {
    script = [
      [n(1)],
      [n(2), n(1)],
    ];
    live = make();
    live.start();
    await t.pump();
    live.stop();
    live.start();
    await t.pump();
    expect(got, isEmpty);
    live.dispose();
  });

  testWidgets('lỗi mạng bị bỏ qua và poll tiếp được', (t) async {
    var i = 0;
    final l = LiveUpdates(() async {
      i++;
      if (i == 2) throw Exception('mạng');
      return LivePollResult([n(i)]);
    });
    l.events.listen(got.add);
    l.start();
    await t.pump();
    await t.pump(const Duration(seconds: 10));
    await t.pump(const Duration(seconds: 10));
    expect(got.map((e) => e.id), [3]);
    l.dispose();
  });

  testWidgets('pollNow khi đang poll không gọi chồng', (t) async {
    var active = 0;
    var maxActive = 0;
    final l = LiveUpdates(() async {
      active++;
      if (active > maxActive) maxActive = active;
      await Future<void>.delayed(const Duration(seconds: 1));
      active--;
      return LivePollResult([n(1)]);
    });
    l.start();
    l.pollNow();
    l.pollNow();
    await t.pump(const Duration(seconds: 3));
    expect(maxActive, 1);
    l.dispose();
  });

  testWidgets('notifyLocalChange phát sự kiện cục bộ', (t) async {
    script = [[]];
    live = make();
    live.notifyLocalChange();
    await t.pump();
    expect(got.single.type, NotificationTypes.localAttendanceChanged);
    live.dispose();
  });

  testWidgets('SnackBar chỉ báo thông báo mới, bỏ qua nhắc chấm công và lần đầu', (t) async {
    final key = GlobalKey<ScaffoldMessengerState>();
    await t.pumpWidget(MaterialApp(scaffoldMessengerKey: key, home: const Scaffold(body: SizedBox())));
    script = [
      [n(1)],
      [n(3, 'CheckInReminder'), n(2, 'LeaveApproved'), n(1)],
    ];
    live = make(key: key);
    live.start();
    await t.pump();
    expect(find.text('tb 1'), findsNothing);
    await t.pump(const Duration(seconds: 10));
    await t.pump();
    expect(find.text('tb 2'), findsOneWidget);
    expect(find.text('tb 3'), findsNothing);
    live.dispose();
  });
}
