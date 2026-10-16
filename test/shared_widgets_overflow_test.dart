import 'package:enterprise_management/shared/widgets/confirm_dialog.dart';
import 'package:enterprise_management/shared/widgets/feature_placeholder.dart';
import 'package:enterprise_management/shared/widgets/state_views.dart';
import 'package:enterprise_management/shared/widgets/status_chip.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const _longText =
    'Không thể tải dữ liệu từ máy chủ, vui lòng kiểm tra kết nối mạng của bạn rồi thử lại sau ít phút. '
    'Nếu lỗi vẫn tiếp diễn hãy liên hệ quản trị viên hệ thống để được hỗ trợ.';

void main() {
  const sizes = [Size(320, 568), Size(360, 640), Size(393, 852), Size(412, 915), Size(600, 960)];
  const scales = [1.0, 1.3, 1.6, 2.0];

  Future<void> pump(WidgetTester tester, Size size, double scale, Widget home) async {
    tester.view.physicalSize = size * 3;
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(size: size, textScaler: TextScaler.linear(scale)),
          child: home,
        ),
      ),
    );
  }

  for (final size in sizes) {
    for (final scale in scales) {
      final tag = '${size.width.toInt()}x${size.height.toInt()}, chữ x$scale';

      testWidgets('ErrorView/EmptyView không tràn ở $tag', (tester) async {
        await pump(tester, size, scale, Scaffold(body: ErrorView(message: _longText, onRetry: () {})));
        expect(tester.takeException(), isNull);
        await pump(tester, size, scale, const Scaffold(body: EmptyView(message: _longText)));
        expect(tester.takeException(), isNull);
      });

      testWidgets('EmptyView trong ListView không lỗi ở $tag', (tester) async {
        await pump(
          tester,
          size,
          scale,
          const Scaffold(body: SizedBox.expand(child: _EmptyInList())),
        );
        expect(tester.takeException(), isNull);
      });

      testWidgets('StatusChip/FeaturePlaceholder không tràn ở $tag', (tester) async {
        await pump(
          tester,
          size,
          scale,
          Scaffold(
            body: Row(
              children: const [
                Expanded(child: StatusChip(label: 'Chờ xác nhận', color: StatusChip.warning)),
                Expanded(child: StatusChip(label: 'Đang hoạt động', color: StatusChip.success)),
              ],
            ),
          ),
        );
        expect(tester.takeException(), isNull);
        await pump(tester, size, scale, const FeaturePlaceholder('Quản trị hệ thống và phân quyền người dùng'));
        expect(tester.takeException(), isNull);
      });

      testWidgets('confirmDialog không tràn ở $tag', (tester) async {
        late BuildContext ctx;
        await pump(
          tester,
          size,
          scale,
          Scaffold(
            body: Builder(
              builder: (c) {
                ctx = c;
                return const SizedBox();
              },
            ),
          ),
        );
        confirmDialog(ctx, title: 'Cho nhân viên nghỉ việc?', message: _longText, confirmText: 'Cho nghỉ việc', danger: true);
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      });
    }
  }
}

class _EmptyInList extends StatelessWidget {
  const _EmptyInList();

  @override
  Widget build(BuildContext context) =>
      ListView(children: const [SizedBox(height: 80), EmptyView(message: 'Không có yêu cầu nào chờ xử lý.')]);
}
