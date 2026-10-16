import 'package:enterprise_management/features/admin/widgets/admin_common.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const sizes = [Size(320, 568), Size(360, 640), Size(393, 852), Size(412, 915), Size(600, 960)];
  const scales = [1.0, 1.3, 1.6, 2.0];

  for (final size in sizes) {
    for (final scale in scales) {
      testWidgets('InfoLine/FormSheet không tràn ở ${size.width.toInt()}x${size.height.toInt()}, chữ x$scale',
          (tester) async {
        tester.view.physicalSize = size * 3;
        tester.view.devicePixelRatio = 3;
        addTearDown(tester.view.reset);
        await tester.pumpWidget(
          MaterialApp(
            home: MediaQuery(
              data: MediaQueryData(size: size, textScaler: TextScaler.linear(scale)),
              child: Scaffold(
                body: FormSheet(
                  title: 'Tạo tài khoản cho Nguyễn Văn Một Cái Tên Rất Dài',
                  children: [
                    const InfoLine('Đăng nhập cuối', 'nguyenvanmotcaitenratdai.example@congty-rat-dai.com.vn'),
                    const InfoLine('Điện thoại', ''),
                    for (var i = 0; i < 6; i++) TextField(decoration: fieldDecoration('Trường số $i')),
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
