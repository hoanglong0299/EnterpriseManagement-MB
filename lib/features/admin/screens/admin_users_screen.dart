import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/network/api_client.dart';
import '../../../core/utils/helpers.dart';
import '../../../models/admin_user.dart';
import '../../../services/admin_service.dart';
import '../../../shared/widgets/confirm_dialog.dart';
import '../../../shared/widgets/permission_gate.dart';
import '../../../shared/widgets/state_views.dart';
import '../../../shared/widgets/status_chip.dart';
import '../providers/admin_users_provider.dart';
import '../widgets/admin_common.dart';

// Admin > Tài khoản (tương ứng AdminUsersApiPage bên web): lọc theo mã/tên nhân viên,
// tạo tài khoản (gắn nhân viên + vai trò), sửa, khoá/mở, đặt lại mật khẩu. Quyền: user.manage.
class AdminUsersScreen extends StatelessWidget {
  const AdminUsersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (ctx) => AdminUsersProvider(AdminService(ctx.read<ApiClient>()))..load(),
      child: const _UsersView(),
    );
  }
}

class _UsersView extends StatelessWidget {
  const _UsersView();

  // Form tạo (user == null) hoặc sửa tài khoản.
  Future<void> _openForm(BuildContext context, {AdminUser? user}) async {
    final provider = context.read<AdminUsersProvider>();
    final username = TextEditingController(text: user?.username ?? '');
    final email = TextEditingController(text: user?.email ?? '');
    final roleCodes = TextEditingController(text: user?.roles.join(', ') ?? '');
    String? roleCode = provider.roles.isNotEmpty ? provider.roles.first.roleCode : null;
    String? employeeCode = user?.employeeCode;
    // Nếu tài khoản đang gắn nhân viên không có trong danh sách (thiếu quyền xem) thì giữ nguyên giá trị.
    final employeeItems = provider.employees;
    final employeeInList = employeeItems.any((e) => e.employeeCode == employeeCode);

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) {
        bool saving = false;
        return StatefulBuilder(
          builder: (_, setState) => FormSheet(
            title: user == null ? 'Tạo tài khoản' : 'Sửa tài khoản',
            children: [
              TextField(controller: username, enabled: user == null, decoration: fieldDecoration('Tên đăng nhập *')),
              const SizedBox(height: 12),
              TextField(
                controller: email,
                keyboardType: TextInputType.emailAddress,
                decoration: fieldDecoration('Email *'),
              ),
              const SizedBox(height: 12),
              if (user == null)
                DropdownButtonFormField<String>(
                  initialValue: roleCode,
                  isExpanded: true,
                  decoration: fieldDecoration('Vai trò *'),
                  items: [
                    for (final r in provider.roles)
                      DropdownMenuItem(value: r.roleCode, child: Text('${r.roleName} (${r.roleCode})')),
                  ],
                  onChanged: (v) => setState(() => roleCode = v),
                )
              else
                TextField(
                  controller: roleCodes,
                  decoration: fieldDecoration('Vai trò (mã, cách nhau bằng dấu phẩy)'),
                ),
              const SizedBox(height: 12),
              if (employeeItems.isNotEmpty)
                DropdownButtonFormField<String?>(
                  initialValue: employeeInList ? employeeCode : null,
                  isExpanded: true,
                  decoration: fieldDecoration('Nhân viên'),
                  items: [
                    const DropdownMenuItem<String?>(value: null, child: Text('Không gắn nhân viên')),
                    for (final e in employeeItems)
                      DropdownMenuItem<String?>(
                        value: e.employeeCode,
                        child: Text('${e.fullName} (${e.employeeCode})', overflow: TextOverflow.ellipsis),
                      ),
                  ],
                  onChanged: (v) => setState(() => employeeCode = v),
                )
              else
                TextFormField(
                  initialValue: employeeCode,
                  decoration: fieldDecoration('Mã nhân viên'),
                  onChanged: (v) => employeeCode = v.trim().isEmpty ? null : v.trim(),
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
                        if (user == null && roleCode == null) {
                          showMessage(sheetContext, 'Vui lòng chọn vai trò cho tài khoản này.', error: true);
                          return;
                        }
                        setState(() => saving = true);
                        AdminCredential? credential;
                        final ok = await runAdminAction(
                          sheetContext,
                          () async {
                            if (user == null) {
                              credential = await provider.create(
                                username: username.text.trim(),
                                email: email.text.trim(),
                                roleCode: roleCode!,
                                employeeCode: employeeCode,
                              );
                            } else {
                              await provider.update(
                                user,
                                email: email.text.trim(),
                                employeeCode: employeeCode,
                                roleCodes: roleCodes.text
                                    .split(',')
                                    .map((s) => s.trim())
                                    .where((s) => s.isNotEmpty)
                                    .toList(),
                              );
                            }
                          },
                          user == null ? 'Đã tạo tài khoản.' : 'Đã cập nhật tài khoản.',
                        );
                        if (!sheetContext.mounted) return;
                        if (!ok) {
                          setState(() => saving = false);
                          return;
                        }
                        final navigator = Navigator.of(sheetContext);
                        final root = context;
                        navigator.pop();
                        if (credential != null && root.mounted) await showCredentialSheet(root, credential!);
                      },
                child: saving
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                    : Text(user == null ? 'Tạo tài khoản' : 'Lưu thay đổi'),
              ),
            ],
          ),
        );
      },
    );
    username.dispose();
    email.dispose();
    roleCodes.dispose();
  }

  Future<void> _toggle(BuildContext context, AdminUser u) async {
    final provider = context.read<AdminUsersProvider>();
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
      () => provider.setActive(u, !u.isActive),
      u.isActive ? 'Đã khóa tài khoản.' : 'Đã mở khóa tài khoản.',
    );
  }

  Future<void> _reset(BuildContext context, AdminUser u) async {
    final provider = context.read<AdminUsersProvider>();
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

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AdminUsersProvider>();
    final list = provider.filtered;
    return Scaffold(
      backgroundColor: adminBackground,
      appBar: AppBar(title: const Text('Tài khoản')),
      floatingActionButton: PermissionGate(
        code: 'user.manage',
        child: FloatingActionButton.extended(
          onPressed: () => _openForm(context),
          icon: const Icon(Icons.person_add),
          label: const Text('Tạo tài khoản'),
        ),
      ),
      body: Builder(builder: (_) {
        if (provider.isLoading && provider.users.isEmpty) return const LoadingView();
        if (provider.errorMessage != null) {
          return ErrorView(message: provider.errorMessage!, onRetry: provider.load);
        }
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: Row(
                children: [
                  Expanded(
                    child: AdminSearchField(hint: 'Mã nhân viên', onChanged: (v) => provider.setFilters(code: v)),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: AdminSearchField(hint: 'Tên nhân viên', onChanged: (v) => provider.setFilters(name: v)),
                  ),
                ],
              ),
            ),
            Expanded(
              child: list.isEmpty
                  ? EmptyView(message: provider.hasFilters ? 'Không có tài khoản phù hợp.' : 'Chưa có tài khoản.')
                  : RefreshIndicator(
                      onRefresh: provider.load,
                      child: ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 88),
                        itemCount: list.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (_, i) {
                          final u = list[i];
                          return Card(
                            margin: EdgeInsets.zero,
                            child: Padding(
                              padding: const EdgeInsets.all(14),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(u.username,
                                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                                      ),
                                      StatusChip(
                                        label: u.isActive ? 'Đang hoạt động' : 'Đã khóa',
                                        color: u.isActive ? StatusChip.success : StatusChip.danger,
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  InfoLine('Email', u.email),
                                  InfoLine('Nhân viên',
                                      u.employeeCode == null ? '' : '${u.employeeName ?? ''} (${u.employeeCode})'),
                                  InfoLine('Vai trò', u.roles.join(', ')),
                                  InfoLine('Đăng nhập cuối', formatDateTime(u.lastLoginAt)),
                                  PermissionGate(
                                    code: 'user.manage',
                                    child: Wrap(
                                      alignment: WrapAlignment.end,
                                      children: [
                                        TextButton(
                                            onPressed: () => _openForm(context, user: u), child: const Text('Sửa')),
                                        TextButton(
                                          onPressed: () => _toggle(context, u),
                                          child: Text(u.isActive ? 'Khóa' : 'Mở khóa'),
                                        ),
                                        TextButton(
                                            onPressed: () => _reset(context, u),
                                            child: const Text('Đặt lại mật khẩu')),
                                      ],
                                    ),
                                  ),
                                ],
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
