import 'package:enterprise_management/features/utilities/widgets/utility_grid.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// Tên chức năng dài nhất trong app (menu của Admin/HR/Quản lý) để kiểm tra không bị tràn.
const _titles = [
  'Tổng quan',
  'Điều chỉnh chấm công',
  'Xin nghỉ phép',
  'Duyệt đơn xin nghỉ',
  'Chấm công toàn công ty',
  'Ghi nhận chấm công',
  'Xử lý điều chỉnh công',
  'Xử lý đi làm lại',
  'Phòng ban & chức vụ',
  'Quản trị hệ thống',
  'Nhật ký hệ thống',
  'Quản lý nhân viên',
  'Loại nghỉ phép',
  'Tổng quan phòng ban',
];

void main() {
  // [rộng, cao] theo dp của các cỡ điện thoại phổ biến, từ rất nhỏ đến lớn.
  const sizes = [Size(320, 568), Size(360, 640), Size(393, 852), Size(412, 915), Size(600, 960)];
  const scales = [0.85, 1.0, 1.3, 1.6, 2.0];

  for (final size in sizes) {
    for (final scale in scales) {
      testWidgets('UtilityGrid không tràn ở ${size.width.toInt()}x${size.height.toInt()}, chữ x$scale', (tester) async {
        tester.view.physicalSize = size * 3;
        tester.view.devicePixelRatio = 3;
        addTearDown(tester.view.reset);

        await tester.pumpWidget(
          MaterialApp(
            home: MediaQuery(
              data: MediaQueryData(size: size, textScaler: TextScaler.linear(scale)),
              child: Scaffold(
                body: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: UtilityGrid(
                    items: [
                      for (final t in _titles)
                        UtilityItem(title: t, icon: Icons.apps, color: Colors.indigo, onTap: () {}),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );

        // Lỗi tràn (RenderFlex overflowed) được Flutter ghi thành exception trong lúc dựng.
        expect(tester.takeException(), isNull);
      });
    }
  }
}
