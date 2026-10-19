import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/network/api_client.dart';
import '../../../core/utils/helpers.dart';
import '../../../models/admin_employee.dart';
import '../../../services/admin_service.dart';
import '../../../shared/widgets/confirm_dialog.dart';
import '../../../shared/widgets/permission_gate.dart';
import '../../../shared/widgets/state_views.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/admin_employees_provider.dart';
import '../widgets/admin_common.dart';
import '../widgets/employee_account_widgets.dart';

// Admin > Quản lý nhân viên (tương ứng AdminEmployeesPage bên web): mỗi nhân viên = 1 hồ sơ + 1 tài khoản.
// Tạo (kèm tài khoản, hiện mật khẩu sinh), sửa hồ sơ/email/vai trò, đặt lại mật khẩu,
// khoá/mở tài khoản, cho nghỉ việc/phục hồi. Quyền: employee.view.all, employee.manage, user.manage.
class AdminEmployeesScreen extends StatelessWidget {
  const AdminEmployeesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (ctx) => AdminEmployeesProvider(AdminService(ctx.read<ApiClient>()))..load(),
      child: const _EmployeesView(),
    );
  }
}

String _genderLabel(String? g) => switch (g) {
  'Male' => 'Nam',
  'Female' => 'Nữ',
  'Other' => 'Khác',
  _ => '',
};

class _EmployeesView extends StatelessWidget {
  const _EmployeesView();

  // Form thêm (employee == null) hoặc sửa hồ sơ.
  Future<void> _openForm(BuildContext context, {AdminEmployee? employee}) async {
    final provider = context.read<AdminEmployeesProvider>();
    final editing = employee != null;
    final lastName = TextEditingController(text: employee?.lastName ?? '');
    final firstName = TextEditingController(text: employee?.firstName ?? '');
    final username = TextEditingController();
    final email = TextEditingController(text: employee?.email ?? '');
    final phone = TextEditingController(text: employee?.phone ?? '');
    final address = TextEditingController(text: employee?.address ?? '');
    String gender = 'Male';
    DateTime? dob;
    DateTime hireDate = DateTime.now();
    String? departmentCode =
        employee?.departmentCode ??
        (provider.departments.isNotEmpty ? provider.departments.first.departmentCode : null);
    String? positionCode =
        employee?.positionCode ?? (provider.positions.isNotEmpty ? provider.positions.first.positionCode : null);
    String? managerCode = employee?.managerCode;

    // Vai trò: tạo -> chọn 1 (null = mặc định theo chức vụ); sửa -> chọn nhiều.
    String? roleCode;
    bool roleTouched = false;
    final selectedRoles = <String>{...?employee?.roleCodes};
    // Vai trò hiện có của nhân viên nhưng không nằm trong danh sách (thiếu quyền xem/vai trò đã tắt) vẫn hiện để giữ.
    final roleOptions = <AdminRole>[
      ...provider.roles,
      if (employee != null)
        for (var i = 0; i < employee.roleCodes.length; i++)
          if (!provider.roles.any((r) => r.roleCode == employee.roleCodes[i]))
            AdminRole(
              roleCode: employee.roleCodes[i],
              roleName: i < employee.roleNames.length ? employee.roleNames[i] : employee.roleCodes[i],
              isActive: true,
            ),
    ];

    String? defaultRoleFor(String? posCode) {
      for (final p in provider.positions) {
        if (p.positionCode == posCode && p.roleCode != null && provider.roles.any((r) => r.roleCode == p.roleCode)) {
          return p.roleCode;
        }
      }
      return null;
    }

    roleCode = defaultRoleFor(positionCode);

    // Ứng viên quản lý: cùng phòng ban đã chọn, chưa nghỉ việc, không phải chính mình;
    // vẫn giữ quản lý hiện tại (nếu khác phòng) để mở form Sửa không mất lựa chọn.
    List<AdminEmployee> managerCandidates() {
      final list = provider.employees
          .where((e) => e.departmentCode == departmentCode && e.isActive && e.employeeCode != employee?.employeeCode)
          .toList();
      if (managerCode != null && !list.any((e) => e.employeeCode == managerCode)) {
        final current = provider.employees.where((e) => e.employeeCode == managerCode);
        if (current.isNotEmpty) list.insert(0, current.first);
      }
      return list;
    }

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) {
        bool saving = false;
        return StatefulBuilder(
          builder: (_, setState) {
            final candidates = managerCandidates();
            return FormSheet(
              title: editing ? 'Sửa hồ sơ: ${employee.fullName}' : 'Thêm nhân viên mới',
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextField(controller: lastName, decoration: fieldDecoration('Họ *')),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(controller: firstName, decoration: fieldDecoration('Tên *')),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: phone,
                  keyboardType: TextInputType.phone,
                  decoration: fieldDecoration('Điện thoại'),
                ),
                const SizedBox(height: 12),
                TextField(controller: address, decoration: fieldDecoration('Địa chỉ')),
                const SizedBox(height: 12),
                if (!editing) ...[
                  Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: () async {
                            final picked = await showDatePicker(
                              context: sheetContext,
                              initialDate: dob ?? DateTime(1995),
                              firstDate: DateTime(1940),
                              lastDate: DateTime.now(),
                            );
                            if (picked != null) setState(() => dob = picked);
                          },
                          child: InputDecorator(
                            decoration: fieldDecoration('Ngày sinh'),
                            child: Text(dob == null ? 'Chọn ngày' : formatDate(dob), overflow: TextOverflow.ellipsis),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          initialValue: gender,
                          isExpanded: true,
                          decoration: fieldDecoration('Giới tính'),
                          items: const [
                            DropdownMenuItem(value: 'Male', child: Text('Nam')),
                            DropdownMenuItem(value: 'Female', child: Text('Nữ')),
                            DropdownMenuItem(value: 'Other', child: Text('Khác')),
                          ],
                          onChanged: (v) => setState(() => gender = v ?? 'Male'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                ],
                DropdownButtonFormField<String>(
                  initialValue: departmentCode,
                  isExpanded: true,
                  decoration: fieldDecoration('Phòng ban *'),
                  items: [
                    for (final d in provider.departments)
                      DropdownMenuItem(
                        value: d.departmentCode,
                        child: Text(d.departmentName, overflow: TextOverflow.ellipsis),
                      ),
                  ],
                  onChanged: (v) => setState(() {
                    departmentCode = v;
                    // Đổi phòng ban thì bỏ quản lý nếu người đó không thuộc phòng mới.
                    final valid = provider.employees.any((e) => e.employeeCode == managerCode && e.departmentCode == v);
                    if (!valid) managerCode = null;
                  }),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: positionCode,
                  isExpanded: true,
                  decoration: fieldDecoration('Chức vụ *'),
                  items: [
                    for (final p in provider.positions)
                      DropdownMenuItem(
                        value: p.positionCode,
                        child: Text(p.positionName, overflow: TextOverflow.ellipsis),
                      ),
                  ],
                  onChanged: (v) => setState(() {
                    positionCode = v;
                    // Chưa tự chọn vai trò thì vai trò mặc định đổi theo chức vụ.
                    if (!editing && !roleTouched) roleCode = defaultRoleFor(v);
                  }),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String?>(
                  key: ValueKey('mgr-$departmentCode'),
                  initialValue: candidates.any((e) => e.employeeCode == managerCode) ? managerCode : null,
                  isExpanded: true,
                  decoration: fieldDecoration('Quản lý trực tiếp'),
                  items: [
                    const DropdownMenuItem<String?>(
                      value: null,
                      child: Text('Không có', overflow: TextOverflow.ellipsis),
                    ),
                    for (final m in candidates)
                      DropdownMenuItem<String?>(
                        value: m.employeeCode,
                        child: Text('${m.fullName} (${m.employeeCode})', overflow: TextOverflow.ellipsis),
                      ),
                  ],
                  onChanged: (v) => setState(() => managerCode = v),
                ),
                if (departmentCode != null && candidates.isEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      'Phòng ban này chưa có nhân viên nào khác để chọn làm quản lý.',
                      style: TextStyle(color: Colors.red.shade700, fontSize: 12),
                    ),
                  ),
                if (!editing) ...[
                  const SizedBox(height: 12),
                  InkWell(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: sheetContext,
                        initialDate: hireDate,
                        firstDate: DateTime(2000),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                      );
                      if (picked != null) setState(() => hireDate = picked);
                    },
                    child: InputDecorator(
                      decoration: fieldDecoration('Ngày vào làm *'),
                      child: Text(formatDate(hireDate)),
                    ),
                  ),
                ],
                const SizedBox(height: 20),
                const Text('Tài khoản đăng nhập', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                if (!editing) ...[
                  TextField(
                    controller: username,
                    autocorrect: false,
                    decoration: fieldDecoration('Tên đăng nhập *', hint: '3-50 ký tự: chữ, số, . _ -'),
                  ),
                  const SizedBox(height: 12),
                ],
                TextField(
                  controller: email,
                  keyboardType: TextInputType.emailAddress,
                  autocorrect: false,
                  decoration: fieldDecoration('Email *'),
                ),
                const SizedBox(height: 12),
                if (!editing)
                  if (provider.roles.isEmpty)
                    Text(
                      'Vai trò sẽ được gán theo chức vụ đã chọn.',
                      style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                    )
                  else
                    DropdownButtonFormField<String?>(
                      key: ValueKey('role-$positionCode-$roleTouched'),
                      initialValue: roleCode,
                      isExpanded: true,
                      decoration: fieldDecoration('Vai trò'),
                      items: [
                        const DropdownMenuItem<String?>(
                          value: null,
                          child: Text('Mặc định theo chức vụ', overflow: TextOverflow.ellipsis),
                        ),
                        for (final r in provider.roles)
                          DropdownMenuItem<String?>(
                            value: r.roleCode,
                            child: Text('${r.roleName} (${r.roleCode})', overflow: TextOverflow.ellipsis),
                          ),
                      ],
                      onChanged: (v) => setState(() {
                        roleCode = v;
                        roleTouched = true;
                      }),
                    )
                else ...[
                  Text('Vai trò (chọn một hoặc nhiều)', style: TextStyle(color: Colors.grey.shade700, fontSize: 13)),
                  const SizedBox(height: 6),
                  RoleChips(
                    roles: roleOptions,
                    selected: selectedRoles,
                    onToggle: (code) => setState(() {
                      if (!selectedRoles.remove(code)) selectedRoles.add(code);
                    }),
                  ),
                ],
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: saving
                      ? null
                      : () async {
                          if (departmentCode == null || positionCode == null) {
                            showMessage(sheetContext, 'Vui lòng chọn phòng ban và chức vụ.', error: true);
                            return;
                          }
                          if (firstName.text.trim().isEmpty || lastName.text.trim().isEmpty) {
                            showMessage(sheetContext, 'Vui lòng nhập đủ họ tên.', error: true);
                            return;
                          }
                          final problem =
                              (editing ? null : validateUsername(username.text)) ?? validateEmail(email.text);
                          if (problem != null) {
                            showMessage(sheetContext, problem, error: true);
                            return;
                          }
                          if (editing && selectedRoles.isEmpty) {
                            showMessage(sheetContext, 'Vui lòng chọn ít nhất một vai trò.', error: true);
                            return;
                          }
                          setState(() => saving = true);
                          String? opt(TextEditingController c) => c.text.trim().isEmpty ? null : c.text.trim();
                          AdminCredential? credential;
                          final ok = await runAdminAction(sheetContext, () async {
                            if (editing) {
                              await provider.update(
                                employee,
                                firstName: firstName.text.trim(),
                                lastName: lastName.text.trim(),
                                email: email.text.trim(),
                                roleCodes: selectedRoles.toList(),
                                phone: opt(phone),
                                address: opt(address),
                                departmentCode: departmentCode!,
                                positionCode: positionCode!,
                                managerCode: managerCode,
                              );
                            } else {
                              credential = await provider.create(
                                firstName: firstName.text.trim(),
                                lastName: lastName.text.trim(),
                                username: username.text.trim(),
                                email: email.text.trim(),
                                roleCode: roleCode,
                                phone: opt(phone),
                                address: opt(address),
                                dateOfBirth: dob == null ? null : isoDate(dob!),
                                gender: gender,
                                departmentCode: departmentCode!,
                                positionCode: positionCode!,
                                managerCode: managerCode,
                                hireDate: isoDate(hireDate),
                              );
                            }
                          }, editing ? 'Đã cập nhật hồ sơ nhân viên.' : 'Đã thêm nhân viên mới.');
                          if (!sheetContext.mounted) return;
                          if (!ok) {
                            setState(() => saving = false);
                            return;
                          }
                          Navigator.pop(sheetContext);
                          // Mật khẩu sinh ra chỉ hiện một lần ngay sau khi tạo.
                          if (credential != null && context.mounted) await showCredentialSheet(context, credential!);
                        },
                  child: saving
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                      : Text(editing ? 'Lưu thay đổi' : 'Thêm nhân viên'),
                ),
              ],
            );
          },
        );
      },
    );
    lastName.dispose();
    firstName.dispose();
    username.dispose();
    email.dispose();
    phone.dispose();
    address.dispose();
  }

  // Khoá / mở khoá: khoá = chuyển sang Đã nghỉ việc và khoá tài khoản đăng nhập; mở khoá = phục hồi cả hai. Luôn xác nhận khi khoá.
  Future<void> _toggleEmployment(BuildContext context, AdminEmployee e) async {
    final provider = context.read<AdminEmployeesProvider>();
    final locking = e.isActive;
    if (locking) {
      final ok = await confirmDialog(
        context,
        title: 'Khoá nhân viên?',
        message: 'Nhân viên "${e.fullName}" sẽ chuyển sang trạng thái Đã nghỉ việc và tài khoản đăng nhập "${e.username}" sẽ bị khoá.',
        confirmText: 'Khoá',
        danger: true,
      );
      if (!ok || !context.mounted) return;
    }
    await runAdminAction(
      context,
      () => provider.setActive(e, !locking),
      locking ? 'Đã khoá nhân viên và tài khoản.' : 'Đã mở khoá nhân viên và tài khoản.',
    );
  }

  Future<void> _resetPassword(BuildContext context, AdminEmployee e) async {
    final provider = context.read<AdminEmployeesProvider>();
    final ok = await confirmDialog(
      context,
      title: 'Đặt lại mật khẩu?',
      message: 'Tạo mật khẩu tạm mới cho "${e.username}". Mật khẩu cũ sẽ không dùng được nữa.',
      confirmText: 'Đặt lại',
    );
    if (!ok || !context.mounted) return;
    AdminCredential? credential;
    final done = await runAdminAction(
      context,
      () async => credential = await provider.resetPassword(e),
      'Đã đặt lại mật khẩu.',
    );
    if (done && credential != null && context.mounted) await showCredentialSheet(context, credential!);
  }

  // Xem chi tiết hồ sơ.
  void _showDetail(BuildContext context, AdminEmployee e) {
    final provider = context.read<AdminEmployeesProvider>();
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => FormSheet(
        title: e.fullName,
        children: [
          InfoLine('Mã NV', e.employeeCode),
          InfoLine('Tên đăng nhập', e.username),
          InfoLine('Vai trò', e.roleNames.isNotEmpty ? e.roleNames.join(', ') : e.roleCodes.join(', ')),
          InfoLine('Tài khoản', e.isAccountActive ? 'Hoạt động' : 'Đã khoá'),
          InfoLine('Đăng nhập cuối', e.lastLoginAt == null ? '' : formatDateTime(e.lastLoginAt)),
          InfoLine('Email', e.email),
          InfoLine('Điện thoại', e.phone ?? ''),
          InfoLine('Địa chỉ', e.address ?? ''),
          InfoLine('Ngày sinh', e.dateOfBirth == null ? '' : formatDate(e.dateOfBirth)),
          InfoLine('Giới tính', _genderLabel(e.gender)),
          InfoLine('Phòng ban', e.departmentName),
          InfoLine('Chức vụ', e.positionName),
          InfoLine('Quản lý', provider.managerName(e)),
          InfoLine('Ngày vào làm', e.hireDate == null ? '' : formatDate(e.hireDate)),
          InfoLine('Trạng thái', employmentStatusLabel(e.employmentStatus)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AdminEmployeesProvider>();
    final auth = context.watch<AuthProvider>();
    final canManage = auth.can('employee.manage');
    final canAccount = auth.can('user.manage');
    final list = provider.filtered;
    return Scaffold(
      backgroundColor: adminBackground,
      appBar: AppBar(title: const Text('Quản lý nhân viên')),
      floatingActionButton: PermissionGate(
        code: 'employee.manage',
        child: FloatingActionButton.extended(
          onPressed: () => _openForm(context),
          icon: const Icon(Icons.person_add),
          label: const Text('Thêm nhân viên'),
        ),
      ),
      body: Builder(
        builder: (_) {
          if (provider.isLoading && provider.employees.isEmpty) return const LoadingView();
          if (provider.errorMessage != null) {
            return ErrorView(message: provider.errorMessage!, onRetry: provider.load);
          }
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                child: Column(
                  children: [
                    AdminSearchField(hint: 'Tìm theo tên, mã, email, tên đăng nhập', onChanged: provider.setQuery),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String?>(
                            initialValue: provider.departmentFilter,
                            isExpanded: true,
                            decoration: fieldDecoration('Phòng ban'),
                            items: [
                              const DropdownMenuItem<String?>(value: null, child: Text('Tất cả')),
                              for (final d in provider.departments)
                                DropdownMenuItem<String?>(
                                  value: d.departmentCode,
                                  child: Text(d.departmentName, overflow: TextOverflow.ellipsis),
                                ),
                            ],
                            onChanged: provider.setDepartmentFilter,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: DropdownButtonFormField<String?>(
                            initialValue: provider.statusFilter,
                            isExpanded: true,
                            decoration: fieldDecoration('Trạng thái'),
                            items: [
                              const DropdownMenuItem<String?>(value: null, child: Text('Tất cả')),
                              for (final s in provider.statuses)
                                DropdownMenuItem<String?>(
                                  value: s,
                                  child: Text(employmentStatusLabel(s), overflow: TextOverflow.ellipsis),
                                ),
                            ],
                            onChanged: provider.setStatusFilter,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Expanded(
                child: list.isEmpty
                    ? const EmptyView(message: 'Không có nhân viên phù hợp.')
                    : RefreshIndicator(
                        onRefresh: provider.load,
                        child: ListView.separated(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 88),
                          itemCount: list.length,
                          separatorBuilder: (_, _) => const SizedBox(height: 10),
                          itemBuilder: (_, i) {
                            final e = list[i];
                            return AdminEmployeeCard(
                              employee: e,
                              managerName: provider.managerName(e),
                              canManageEmployee: canManage,
                              canManageAccount: canAccount,
                              onTap: () => _showDetail(context, e),
                              onEdit: () => _openForm(context, employee: e),
                              onToggleEmployment: () => _toggleEmployment(context, e),
                              onResetPassword: () => _resetPassword(context, e),
                            );
                          },
                        ),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}
