import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/network/api_client.dart';
import '../../../core/utils/helpers.dart';
import '../../../models/admin_employee.dart';
import '../../../models/admin_user.dart';
import '../../../services/admin_service.dart';
import '../../../shared/widgets/confirm_dialog.dart';
import '../../../shared/widgets/permission_gate.dart';
import '../../../shared/widgets/state_views.dart';
import '../../../shared/widgets/status_chip.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/admin_employees_provider.dart';
import '../widgets/admin_common.dart';

// Admin > Quản lý nhân viên (tương ứng AdminEmployeesPage bên web): xem toàn bộ nhân viên, tìm/lọc,
// xem chi tiết, thêm/sửa hồ sơ, cho nghỉ việc/phục hồi, tạo và quản lý tài khoản đăng nhập.
// Quyền xem: employee.view.all, ghi: employee.manage, tài khoản: user.manage.
class AdminEmployeesScreen extends StatelessWidget {
  const AdminEmployeesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (ctx) => AdminEmployeesProvider(
        AdminService(ctx.read<ApiClient>()),
        canViewUsers: ctx.read<AuthProvider>().can('user.manage'),
      )..load(),
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

String _statusLabel(String s) => switch (s) {
      'Active' => 'Đang làm việc',
      'Probation' => 'Thử việc',
      'Terminated' => 'Đã nghỉ việc',
      _ => s,
    };

Color _statusColor(String s) => switch (s) {
      'Active' => StatusChip.success,
      'Probation' => StatusChip.warning,
      'Terminated' => StatusChip.danger,
      _ => StatusChip.neutral,
    };

class _EmployeesView extends StatelessWidget {
  const _EmployeesView();

  // Form thêm (employee == null) hoặc sửa hồ sơ.
  Future<void> _openForm(BuildContext context, {AdminEmployee? employee}) async {
    final provider = context.read<AdminEmployeesProvider>();
    final editing = employee != null;
    final lastName = TextEditingController(text: employee?.lastName ?? '');
    final firstName = TextEditingController(text: employee?.firstName ?? '');
    final email = TextEditingController();
    final phone = TextEditingController(text: employee?.phone ?? '');
    final address = TextEditingController(text: employee?.address ?? '');
    String gender = 'Male';
    DateTime? dob;
    DateTime hireDate = DateTime.now();
    String? departmentCode = employee?.departmentCode ??
        (provider.departments.isNotEmpty ? provider.departments.first.departmentCode : null);
    String? positionCode =
        employee?.positionCode ?? (provider.positions.isNotEmpty ? provider.positions.first.positionCode : null);
    String? managerCode = employee?.managerCode;

    // Ứng viên quản lý: cùng phòng ban đã chọn, chưa nghỉ việc, không phải chính mình;
    // vẫn giữ quản lý hiện tại (nếu khác phòng) để mở form Sửa không mất lựa chọn.
    List<AdminEmployee> managerCandidates() {
      final list = provider.employees
          .where((e) =>
              e.departmentCode == departmentCode &&
              e.employmentStatus != 'Terminated' &&
              e.employeeCode != employee?.employeeCode)
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
        return StatefulBuilder(builder: (_, setState) {
          final candidates = managerCandidates();
          return FormSheet(
            title: editing ? 'Sửa hồ sơ: ${employee.fullName}' : 'Thêm nhân viên mới',
            children: [
              Row(
                children: [
                  Expanded(child: TextField(controller: lastName, decoration: fieldDecoration('Họ *'))),
                  const SizedBox(width: 12),
                  Expanded(child: TextField(controller: firstName, decoration: fieldDecoration('Tên *'))),
                ],
              ),
              const SizedBox(height: 12),
              if (!editing) ...[
                TextField(
                  controller: email,
                  keyboardType: TextInputType.emailAddress,
                  decoration: fieldDecoration('Email'),
                ),
                const SizedBox(height: 12),
              ],
              TextField(controller: phone, keyboardType: TextInputType.phone, decoration: fieldDecoration('Điện thoại')),
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
                          child: Text(dob == null ? 'Chọn ngày' : formatDate(dob)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: gender,
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
                    DropdownMenuItem(value: d.departmentCode, child: Text(d.departmentName)),
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
                    DropdownMenuItem(value: p.positionCode, child: Text(p.positionName)),
                ],
                onChanged: (v) => setState(() => positionCode = v),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String?>(
                key: ValueKey('mgr-$departmentCode'),
                initialValue: candidates.any((e) => e.employeeCode == managerCode) ? managerCode : null,
                isExpanded: true,
                decoration: fieldDecoration('Quản lý trực tiếp'),
                items: [
                  const DropdownMenuItem<String?>(value: null, child: Text('Không có')),
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
                  child: Text('Phòng ban này chưa có nhân viên nào khác để chọn làm quản lý.',
                      style: TextStyle(color: Colors.red.shade700, fontSize: 12)),
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
                        setState(() => saving = true);
                        String? opt(TextEditingController c) => c.text.trim().isEmpty ? null : c.text.trim();
                        final ok = await runAdminAction(
                          sheetContext,
                          () => editing
                              ? provider.update(
                                  employee,
                                  firstName: firstName.text.trim(),
                                  lastName: lastName.text.trim(),
                                  phone: opt(phone),
                                  address: opt(address),
                                  departmentCode: departmentCode!,
                                  positionCode: positionCode!,
                                  managerCode: managerCode,
                                )
                              : provider.create(
                                  firstName: firstName.text.trim(),
                                  lastName: lastName.text.trim(),
                                  email: opt(email),
                                  phone: opt(phone),
                                  address: opt(address),
                                  dateOfBirth: dob == null ? null : isoDate(dob!),
                                  gender: gender,
                                  departmentCode: departmentCode!,
                                  positionCode: positionCode!,
                                  managerCode: managerCode,
                                  hireDate: isoDate(hireDate),
                                ),
                          editing ? 'Đã cập nhật hồ sơ nhân viên.' : 'Đã thêm nhân viên mới.',
                        );
                        if (!sheetContext.mounted) return;
                        if (ok) {
                          Navigator.pop(sheetContext);
                        } else {
                          setState(() => saving = false);
                        }
                      },
                child: saving
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                    : Text(editing ? 'Lưu thay đổi' : 'Thêm nhân viên'),
              ),
            ],
          );
        });
      },
    );
    lastName.dispose();
    firstName.dispose();
    email.dispose();
    phone.dispose();
    address.dispose();
  }

  // Cho nghỉ việc cần xác nhận (khoá chấm công/nghỉ phép); phục hồi thì chạy luôn.
  Future<void> _toggle(BuildContext context, AdminEmployee e) async {
    final provider = context.read<AdminEmployeesProvider>();
    if (e.isActive) {
      final ok = await confirmDialog(
        context,
        title: 'Cho nhân viên nghỉ việc?',
        message:
            'Nhân viên "${e.fullName}" sẽ chuyển sang trạng thái Ngừng, không thể chấm công/xin nghỉ nữa cho đến khi được phục hồi lại.',
        confirmText: 'Cho nghỉ việc',
        danger: true,
      );
      if (!ok || !context.mounted) return;
    }
    await runAdminAction(context, () => provider.setActive(e, !e.isActive), 'Đã cập nhật trạng thái nhân viên.');
  }

  Future<void> _createAccount(BuildContext context, AdminEmployee e) async {
    final provider = context.read<AdminEmployeesProvider>();
    final username = TextEditingController(text: e.employeeCode.toLowerCase());
    final email = TextEditingController(text: e.email ?? '');
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) {
        bool saving = false;
        return StatefulBuilder(
          builder: (_, setState) => FormSheet(
            title: 'Tạo tài khoản cho ${e.fullName}',
            children: [
              TextField(controller: username, decoration: fieldDecoration('Tên đăng nhập *')),
              const SizedBox(height: 12),
              TextField(
                controller: email,
                keyboardType: TextInputType.emailAddress,
                decoration: fieldDecoration('Email *'),
              ),
              const SizedBox(height: 8),
              Text(
                'Vai trò được tự lấy theo chức vụ hiện tại (${e.positionName}). Muốn chọn vai trò khác, tạo tại màn hình Tài khoản.',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: saving
                    ? null
                    : () async {
                        if (username.text.trim().isEmpty || email.text.trim().isEmpty) {
                          showMessage(sheetContext, 'Vui lòng nhập đủ tên đăng nhập và email.', error: true);
                          return;
                        }
                        setState(() => saving = true);
                        AdminCredential? credential;
                        final ok = await runAdminAction(
                          sheetContext,
                          () async =>
                              credential = await provider.createAccount(e, username.text.trim(), email.text.trim()),
                          'Đã tạo tài khoản.',
                        );
                        if (!sheetContext.mounted) return;
                        if (!ok) {
                          setState(() => saving = false);
                          return;
                        }
                        Navigator.pop(sheetContext);
                        if (credential != null && context.mounted) await showCredentialSheet(context, credential!);
                      },
                child: saving
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('Tạo tài khoản'),
              ),
            ],
          ),
        );
      },
    );
    username.dispose();
    email.dispose();
  }

  Future<void> _toggleAccount(BuildContext context, AdminUser u) async {
    final provider = context.read<AdminEmployeesProvider>();
    if (u.isActive) {
      final ok = await confirmDialog(
        context,
        title: 'Khóa tài khoản?',
        message: 'Tài khoản "${u.username}" sẽ không thể đăng nhập cho đến khi được mở khóa lại.',
        confirmText: 'Khóa tài khoản',
        danger: true,
      );
      if (!ok || !context.mounted) return;
    }
    await runAdminAction(
      context,
      () => provider.setAccountActive(u, !u.isActive),
      u.isActive ? 'Đã khóa tài khoản.' : 'Đã mở khóa tài khoản.',
    );
  }

  Future<void> _resetAccount(BuildContext context, AdminUser u) async {
    final provider = context.read<AdminEmployeesProvider>();
    final ok = await confirmDialog(
      context,
      title: 'Đặt lại mật khẩu?',
      message: 'Tạo mật khẩu tạm mới cho "${u.username}". Mật khẩu cũ sẽ không dùng được nữa.',
      confirmText: 'Đặt lại',
    );
    if (!ok || !context.mounted) return;
    AdminCredential? credential;
    final done = await runAdminAction(
      context,
      () async => credential = await provider.resetPassword(u),
      'Đã đặt lại mật khẩu.',
    );
    if (done && credential != null && context.mounted) await showCredentialSheet(context, credential!);
  }

  // Danh sách tài khoản của một nhân viên.
  void _manageAccounts(BuildContext context, AdminEmployee e) {
    final provider = context.read<AdminEmployeesProvider>();
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => ChangeNotifierProvider.value(
        value: provider,
        child: Consumer<AdminEmployeesProvider>(
          builder: (_, p, __) {
            final users = p.usersByEmployee[e.employeeCode] ?? [];
            return FormSheet(
              title: 'Tài khoản của ${e.fullName}',
              children: [
                if (users.isEmpty) const Text('Nhân viên chưa có tài khoản.'),
                for (final u in users)
                  Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(child: Text(u.username, style: const TextStyle(fontWeight: FontWeight.bold))),
                              StatusChip(
                                label: u.isActive ? 'Đang hoạt động' : 'Đã khóa',
                                color: u.isActive ? StatusChip.success : StatusChip.danger,
                              ),
                            ],
                          ),
                          InfoLine('Email', u.email),
                          InfoLine('Vai trò', u.roles.join(', ')),
                          InfoLine('Đăng nhập cuối', formatDateTime(u.lastLoginAt)),
                          PermissionGate(
                            code: 'user.manage',
                            child: Wrap(
                              alignment: WrapAlignment.end,
                              children: [
                                TextButton(
                                  onPressed: () => _toggleAccount(sheetContext, u),
                                  child: Text(u.isActive ? 'Khóa' : 'Mở khóa'),
                                ),
                                TextButton(
                                  onPressed: () => _resetAccount(sheetContext, u),
                                  child: const Text('Đặt lại mật khẩu'),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                const Text(
                  'Muốn tạo thêm tài khoản thứ 2 cho nhân viên này, vào màn hình Tài khoản.',
                  style: TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ],
            );
          },
        ),
      ),
    );
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
          InfoLine('Email', e.email ?? ''),
          InfoLine('Điện thoại', e.phone ?? ''),
          InfoLine('Địa chỉ', e.address ?? ''),
          InfoLine('Ngày sinh', e.dateOfBirth == null ? '' : formatDate(e.dateOfBirth)),
          InfoLine('Giới tính', _genderLabel(e.gender)),
          InfoLine('Phòng ban', e.departmentName),
          InfoLine('Chức vụ', e.positionName),
          InfoLine('Quản lý', provider.managerName(e)),
          InfoLine('Ngày vào làm', e.hireDate == null ? '' : formatDate(e.hireDate)),
          InfoLine('Trạng thái', _statusLabel(e.employmentStatus)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AdminEmployeesProvider>();
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
      body: Builder(builder: (_) {
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
                  AdminSearchField(hint: 'Tìm theo tên, mã, email', onChanged: provider.setQuery),
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
                              DropdownMenuItem<String?>(value: s, child: Text(_statusLabel(s))),
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
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (_, i) {
                          final e = list[i];
                          final hasAccount = provider.usersByEmployee[e.employeeCode]?.isNotEmpty ?? false;
                          return Card(
                            margin: EdgeInsets.zero,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(12),
                              onTap: () => _showDetail(context, e),
                              child: Padding(
                                padding: const EdgeInsets.all(14),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(e.fullName,
                                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                                        ),
                                        StatusChip(
                                            label: _statusLabel(e.employmentStatus),
                                            color: _statusColor(e.employmentStatus)),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    InfoLine('Mã NV', e.employeeCode),
                                    InfoLine('Phòng ban', e.departmentName),
                                    InfoLine('Chức vụ', e.positionName),
                                    InfoLine('Quản lý', provider.managerName(e)),
                                    Wrap(
                                      alignment: WrapAlignment.end,
                                      children: [
                                        PermissionGate(
                                          code: 'employee.manage',
                                          child: Wrap(
                                            children: [
                                              TextButton(
                                                  onPressed: () => _openForm(context, employee: e),
                                                  child: const Text('Sửa')),
                                              TextButton(
                                                onPressed: () => _toggle(context, e),
                                                child: Text(e.isActive ? 'Khóa' : 'Mở khóa'),
                                              ),
                                            ],
                                          ),
                                        ),
                                        PermissionGate(
                                          code: 'user.manage',
                                          child: hasAccount
                                              ? TextButton(
                                                  onPressed: () => _manageAccounts(context, e),
                                                  child: const Text('Quản lý tài khoản'))
                                              : TextButton(
                                                  onPressed: () => _createAccount(context, e),
                                                  child: const Text('Tạo tài khoản')),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
            ),
          ],
        );
      }),
    );
  }
}
