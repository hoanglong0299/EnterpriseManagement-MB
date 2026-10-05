import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../core/network/api_client.dart';
import '../../../models/position.dart';
import '../../../services/admin_service.dart';
import '../../../shared/widgets/confirm_dialog.dart';
import '../../../shared/widgets/permission_gate.dart';
import '../../../shared/widgets/state_views.dart';
import '../providers/admin_catalog_provider.dart';
import '../widgets/admin_common.dart';

// Admin > Chức vụ (tương ứng AdminPositionsPage bên web): xem, thêm, sửa, khoá/mở, đặt lương chuẩn.
class AdminPositionsScreen extends StatelessWidget {
  const AdminPositionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (ctx) => AdminPositionsProvider(AdminService(ctx.read<ApiClient>()))..load(),
      child: const _PositionsView(),
    );
  }
}

String _money(double v) => '${NumberFormat('#,##0', 'vi_VN').format(v)} đ';

class _PositionsView extends StatelessWidget {
  const _PositionsView();

  // Form thêm (position == null) hoặc sửa chức vụ.
  Future<void> _openForm(BuildContext context, {Position? position}) async {
    final provider = context.read<AdminPositionsProvider>();
    final code = TextEditingController(text: position?.positionCode ?? '');
    final name = TextEditingController(text: position?.positionName ?? '');
    final desc = TextEditingController(text: position?.description ?? '');
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) {
        bool saving = false;
        return StatefulBuilder(
          builder: (_, setState) => FormSheet(
            title: position == null ? 'Thêm chức vụ' : 'Sửa chức vụ',
            children: [
              TextField(controller: code, enabled: position == null, decoration: fieldDecoration('Mã chức vụ *')),
              const SizedBox(height: 12),
              TextField(controller: name, decoration: fieldDecoration('Tên chức vụ *')),
              const SizedBox(height: 12),
              TextField(controller: desc, maxLines: 3, decoration: fieldDecoration('Mô tả')),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: saving
                    ? null
                    : () async {
                        if (code.text.trim().isEmpty || name.text.trim().isEmpty) {
                          showMessage(sheetContext, 'Vui lòng nhập mã và tên chức vụ.', error: true);
                          return;
                        }
                        setState(() => saving = true);
                        final d = desc.text.trim().isEmpty ? null : desc.text.trim();
                        final ok = await runAdminAction(
                          sheetContext,
                          () => position == null
                              ? provider.create(code.text.trim(), name.text.trim(), d)
                              : provider.update(position, name.text.trim(), d),
                          position == null ? 'Đã thêm chức vụ.' : 'Đã cập nhật chức vụ.',
                        );
                        if (ok && sheetContext.mounted) {
                          Navigator.pop(sheetContext);
                        } else if (sheetContext.mounted) {
                          setState(() => saving = false);
                        }
                      },
                child: saving
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                    : Text(position == null ? 'Thêm mới' : 'Lưu thay đổi'),
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

  Future<void> _editSalary(BuildContext context, Position p) async {
    final provider = context.read<AdminPositionsProvider>();
    final controller = TextEditingController(text: p.standardSalary == null ? '' : p.standardSalary!.toStringAsFixed(0));
    final value = await showDialog<double>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Lương chuẩn: ${p.positionName}'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          autofocus: true,
          decoration: fieldDecoration('Lương chuẩn (đ)'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Huỷ')),
          TextButton(
            onPressed: () {
              final v = double.tryParse(controller.text.trim().replaceAll(RegExp(r'[.,\s]'), ''));
              if (v == null || v < 0) {
                showMessage(ctx, 'Lương chuẩn không hợp lệ.', error: true);
                return;
              }
              Navigator.pop(ctx, v);
            },
            child: const Text('Lưu'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (value == null || !context.mounted) return;
    await runAdminAction(context, () => provider.setSalary(p, value), 'Đã cập nhật lương chuẩn.');
  }

  Future<void> _toggle(BuildContext context, Position p) async {
    final provider = context.read<AdminPositionsProvider>();
    if (p.isActive) {
      final ok = await confirmDialog(
        context,
        title: 'Đóng chức vụ?',
        message: 'Chức vụ "${p.positionName}" sẽ chuyển sang Ngừng hoạt động cho đến khi được mở lại.',
        confirmText: 'Đóng chức vụ',
        danger: true,
      );
      if (!ok || !context.mounted) return;
    }
    await runAdminAction(context, () => provider.setActive(p, !p.isActive), 'Đã cập nhật trạng thái chức vụ.');
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AdminPositionsProvider>();
    return Scaffold(
      backgroundColor: adminBackground,
      appBar: AppBar(title: const Text('Chức vụ')),
      floatingActionButton: PermissionGate(
        code: 'position.manage',
        child: FloatingActionButton.extended(
          onPressed: () => _openForm(context),
          icon: const Icon(Icons.add),
          label: const Text('Thêm chức vụ'),
        ),
      ),
      body: Builder(builder: (_) {
        if (provider.isLoading && provider.items.isEmpty) return const LoadingView();
        if (provider.errorMessage != null) {
          return ErrorView(message: provider.errorMessage!, onRetry: provider.load);
        }
        if (provider.items.isEmpty) return const EmptyView(message: 'Chưa có chức vụ.');
        return RefreshIndicator(
          onRefresh: provider.load,
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 88),
            itemCount: provider.items.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (_, i) {
              final p = provider.items[i];
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
                            child: Text(p.positionName, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                          ),
                          activeChip(p.isActive),
                        ],
                      ),
                      const SizedBox(height: 6),
                      InfoLine('Mã', p.positionCode),
                      InfoLine('Lương chuẩn',
                          p.standardSalary == null || p.standardSalary == 0 ? 'Chưa có lương chuẩn' : _money(p.standardSalary!)),
                      if ((p.description ?? '').isNotEmpty) InfoLine('Mô tả', p.description!),
                      PermissionGate(
                        code: 'position.manage',
                        child: Wrap(
                          alignment: WrapAlignment.end,
                          children: [
                            TextButton(onPressed: () => _openForm(context, position: p), child: const Text('Sửa')),
                            TextButton(onPressed: () => _editSalary(context, p), child: const Text('Lương chuẩn')),
                            TextButton(
                              onPressed: () => _toggle(context, p),
                              child: Text(p.isActive ? 'Khóa' : 'Mở khóa'),
                            ),
                          ],
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
