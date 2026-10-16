import 'package:enterprise_management/core/network/api_client.dart';
import 'package:enterprise_management/core/storage/local_storage.dart';
import 'package:enterprise_management/features/auth/providers/auth_provider.dart';
import 'package:enterprise_management/features/calendar/screens/calendar_screen.dart';
import 'package:enterprise_management/models/attendance_hr.dart';
import 'package:enterprise_management/models/user.dart';
import 'package:enterprise_management/services/auth_service.dart';
import 'package:enterprise_management/services/live_updates.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

void main() {
  late AuthProvider auth;
  late LiveUpdates live;
  late int loads;

  setUp(() {
    final storage = LocalStorage();
    auth = AuthProvider(AuthService(ApiClient(storage)), storage)
      ..session = AuthSession(token: 't', username: 'u', employeeCode: 'E1', roles: const []);
    live = LiveUpdates(() async => const LivePollResult([]));
    loads = 0;
  });
  tearDown(() => live.dispose());

  Widget host(bool active) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthProvider>.value(value: auth),
        Provider<LiveUpdates>.value(value: live),
      ],
      child: MaterialApp(
        home: Scaffold(
          body: CalendarScreen(
            active: active,
            loader: (code, from, to) async {
              loads++;
              return <AttendanceCalendarDay>[];
            },
          ),
        ),
      ),
    );
  }

  testWidgets('active false sang true tải lại tháng đang xem', (t) async {
    await t.pumpWidget(host(false));
    await t.pump();
    expect(loads, 1);
    await t.pumpWidget(host(true));
    await t.pump();
    expect(loads, 2);
    await t.pumpWidget(host(true));
    await t.pump();
    expect(loads, 2);
  });

  testWidgets('tín hiệu cục bộ chấm công làm Lịch tải lại ngay, kể cả tháng đã có cache', (t) async {
    await t.pumpWidget(host(true));
    await t.pump();
    expect(loads, 1);
    live.notifyLocalChange();
    await t.pump();
    expect(loads, 2);
    live.notifyLocalChange();
    await t.pump();
    expect(loads, 3);
  });
}
