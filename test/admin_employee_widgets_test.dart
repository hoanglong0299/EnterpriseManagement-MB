import 'package:enterprise_management/features/admin/widgets/admin_common.dart';
import 'package:enterprise_management/features/admin/widgets/employee_account_widgets.dart';
import 'package:enterprise_management/models/admin_employee.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

AdminEmployee _employee({bool active = true, bool accountActive = true}) => AdminEmployee.fromJson({
      'employeeCode': 'NV0001',
      'firstName': 'Văn Một Cái Tên Rất Dài',
      'lastName': 'Nguyễn Hoàng Thiên',
      'fullName': 'Nguyễn Hoàng Thiên Văn Một Cái Tên Rất Dài',
      'email': 'nguyenvanmotcaitenratdai.example@congty-rat-dai.com.vn',
      'departmentCode': 'IT',
      'departmentName': 'Phòng Công nghệ thông tin và Chuyển đổi số',
      'positionCode': 'DEV',
      'positionName': 'Kỹ sư phần mềm cao cấp',
      'employmentStatus': active ? 'Active' : 'Resigned',
      'username': 'nguyenvanmotcaitenratdai',
      'roleCodes': ['EMPLOYEE', 'MANAGER'],
      'roleNames': ['Nhân viên', 'Quản lý phòng ban'],
      'isAccountActive': accountActive,
      'lastLoginAt': '2026-10-16T17:40:00',
    });

void main() {
  const sizes = [Size(320, 568), Size(360, 640), Size(412, 915)];
  const scales = [1.0, 1.6, 2.0];

  Future<void> pump(WidgetTester tester, Size size, double scale, Widget body) async {
    tester.view.physicalSize = size * 3;
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(size: size, textScaler: TextScaler.linear(scale)),
          child: Scaffold(body: body),
        ),
      ),
    );
  }

  test('validateUsername / validateEmail', () {
    expect(validateUsername('ab'), isNotNull);
    expect(validateUsername('a b c'), isNotNull);
    expect(validateUsername('x' * 51), isNotNull);
    expect(validateUsername('nguyen.van_a-1'), isNull);
    expect(validateEmail('abc'), isNotNull);
    expect(validateEmail('a@b'), isNotNull);
    expect(validateEmail('a@congty.vn'), isNull);
  });

  test('AdminEmployee.fromJson đọc trường tài khoản', () {
    final e = _employee(active: false, accountActive: false);
    expect(e.username, 'nguyenvanmotcaitenratdai');
    expect(e.roleCodes, ['EMPLOYEE', 'MANAGER']);
    expect(e.isActive, isFalse);
    expect(e.isAccountActive, isFalse);
    expect(e.lastLoginAt, isNotNull);
  });

  for (final size in sizes) {
    for (final scale in scales) {
      final tag = '${size.width.toInt()}x${size.height.toInt()}, chữ x$scale';

      testWidgets('AdminEmployeeCard không tràn ở $tag', (tester) async {
        await pump(
          tester,
          size,
          scale,
          SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                AdminEmployeeCard(
                  employee: _employee(),
                  managerName: 'Trần Thị Quản Lý Có Tên Rất Dài',
                  canManageEmployee: true,
                  canManageAccount: true,
                ),
                const SizedBox(height: 10),
                AdminEmployeeCard(
                  employee: _employee(active: false, accountActive: false),
                  canManageEmployee: true,
                  canManageAccount: true,
                ),
              ],
            ),
          ),
        );
        expect(tester.takeException(), isNull);
        expect(find.text('Khoá'), findsOneWidget);
        expect(find.text('Mở khoá'), findsOneWidget);
      });

      testWidgets('Hộp mật khẩu sinh ra không tràn ở $tag', (tester) async {
        await pump(
          tester,
          size,
          scale,
          Builder(
            builder: (context) => TextButton(
              onPressed: () => showCredentialSheet(
                context,
                AdminCredential(username: 'nguyenvanmotcaitenratdai', password: 'AbC123xYz9AbC123xYz9', isReset: false),
              ),
              child: const Text('mở'),
            ),
          ),
        );
        await tester.tap(find.text('mở'));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(find.text('Sao chép'), findsOneWidget);
      });

      testWidgets('Form tạo (FormSheet + RoleChips) không tràn ở $tag', (tester) async {
        final roles = [
          for (var i = 0; i < 5; i++) AdminRole(roleCode: 'R$i', roleName: 'Vai trò số $i khá dài', isActive: true),
        ];
        await pump(
          tester,
          size,
          scale,
          FormSheet(
            title: 'Thêm nhân viên mới',
            children: [
              TextField(decoration: fieldDecoration('Tên đăng nhập *', hint: '3-50 ký tự: chữ, số, . _ -')),
              const SizedBox(height: 12),
              TextField(decoration: fieldDecoration('Email *')),
              const SizedBox(height: 12),
              RoleChips(roles: roles, selected: const {'R1'}, onToggle: (_) {}),
            ],
          ),
        );
        expect(tester.takeException(), isNull);
      });
    }
  }
}
