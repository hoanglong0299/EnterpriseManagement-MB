import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/network/api_client.dart';
import '../../../models/department.dart';
import '../../../services/admin_service.dart';
import '../../../shared/widgets/confirm_dialog.dart';
import '../../../shared/widgets/permission_gate.dart';
import '../../../shared/widgets/state_views.dart';
import '../providers/admin_catalog_provider.dart';
import '../widgets/admin_common.dart';

// Admin > Phòng ban (tương ứng AdminDepartmentsPage bên web): xem, thêm, khoá/mở.
// Backend sửa phòng ban cần managerId (số) mà API không trả ra, nên bản mobile giống web: chỉ thêm và bật/tắt.
class AdminDepartmentsScreen extends StatelessWidget {
  const AdminDepartmentsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (ctx) => AdminDepartmentsProvider(AdminService(ctx.read<ApiClient>()))..load(),
      child: const _DepartmentsView(),
    );
  }
}

class _DepartmentsView extends StatelessWidget {
  const _DepartmentsView();

  Future<void> _openCreate(BuildContext context) async {
    final provider = context.read<AdminDepartmentsProvider>();
    final code = TextEditingController();
    final name = TextEditingController();
    final desc = TextEditingController();
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) {
        bool saving = false;
        return StatefulBuilder(
          builder: (_, setState) => FormSheet(
            title: 'Thêm phòng ban',
            children: [
              TextField(controller: code, decoration: fieldDecoration('Mã phòng ban *')),
              const SizedBox(height: 12),
              TextField(controller: name, decoration: fieldDecoration('Tên phòng ban *')),
              const SizedBox(height: 12),
              TextField(controller: desc, maxLines: 3, decoration: fieldDecoration('Mô tả')),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: saving
                    ? null
                    : () async {
                        if (code.text.trim().isEmpty || name.text.trim().isEmpty) {
                          showMessage(sheetContext, 'Vui lòng nhập mã và tên phòng ban.', error: true);
                          return;
                        }
                        setState(() => saving = true);
                        final ok = await runAdminAction(
                          sheetContext,
                          () => provider.create(code.text.trim(), name.text.trim(),
                              desc.text.trim().isEmpty ? null : desc.text.trim()),
                          'Đã thêm phòng ban.',
                        );
                        if (ok && sheetContext.mounted) {
                          Navigator.pop(sheetContext);
                        } else if (sheetContext.mounted) {
                          setState(() => saving = false);
                        }
                      },
                child: saving
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('Thêm mới'),
              ),
            ],
          ),
        );
      },
    );
    code.dispose();
    name.dispose();
    desc.dispose();
  }

  Future<void> _toggle(BuildContext context, Department d) async {
    final provider = context.read<AdminDepartmentsProvider>();
    if (d.isActive) {
      final ok = await confirmDialog(
        context,
        title: 'Đóng phòng ban?',
        message: 'Phòng ban "${d.departmentName}" sẽ chuyển sang Ngừng hoạt động cho đến khi được mở lại.',
        confirmText: 'Đóng phòng ban',
        danger: true,
      );
      if (!ok || !context.mounted) return;
    }
    await runAdminAction(
      context,
      () => provider.setActive(d, !d.isActive),
      'Đã cập nhật trạng thái phòng ban.',
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AdminDepartmentsProvider>();
    return Scaffold(
      backgroundColor: adminBackground,
      appBar: AppBar(title: const Text('Phòng ban')),
      floatingActionButton: PermissionGate(
        code: 'department.manage',
        child: FloatingActionButton.extended(
          onPressed: () => _openCreate(context),
          icon: const Icon(Icons.add),
          label: const Text('Thêm phòng ban'),
        ),
      ),
      body: Builder(builder: (_) {
        if (provider.isLoading && provider.items.isEmpty) return const LoadingView();
        if (provider.errorMessage != null) {
          return ErrorView(message: provider.errorMessage!, onRetry: provider.load);
        }
        if (provider.items.isEmpty) return const EmptyView(message: 'Chưa có phòng ban.');
        return RefreshIndicator(
          onRefresh: provider.load,
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 88),
            itemCount: provider.items.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (_, i) {
              final d = provider.items[i];
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
                            child: Text(d.departmentName,
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                          ),
                          activeChip(d.isActive),
                        ],
                      ),
                      const SizedBox(height: 6),
                      InfoLine('Mã', d.departmentCode),
                      InfoLine('Trưởng phòng', d.managerName ?? 'Chưa có quản lý'),
                      if ((d.description ?? '').isNotEmpty) InfoLine('Mô tả', d.description!),
                      PermissionGate(
                        code: 'department.manage',
                        child: Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: () => _toggle(context, d),
                            child: Text(d.isActive ? 'Khóa' : 'Mở khóa'),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      }),
    );
  }
}
