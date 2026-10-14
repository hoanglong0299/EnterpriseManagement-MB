import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/network/api_client.dart';
import '../../../models/leave_type_admin.dart';
import '../../../services/leave_type_admin_service.dart';
import '../../../shared/widgets/confirm_dialog.dart';
import '../../../shared/widgets/permission_gate.dart';
import '../../../shared/widgets/state_views.dart';
import '../../../shared/widgets/status_chip.dart';
import '../providers/admin_leave_types_provider.dart';
import '../widgets/leave_type_form_sheet.dart';

const Color _primary = Color(0xFF5A3FD8);

// Admin: quản lý loại nghỉ phép (route /admin/leave-types). Mọi nút ghi cần permission leavetype.manage.
class AdminLeaveTypesScreen extends StatelessWidget {
  const AdminLeaveTypesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (ctx) => AdminLeaveTypesProvider(LeaveTypeAdminService(ctx.read<ApiClient>()))..load(),
      child: const _Body(),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body();

  @override
  Widget build(BuildContext context) {
    final p = context.watch<AdminLeaveTypesProvider>();
    return Scaffold(
      backgroundColor: const Color(0xFFF6F4FC),
      appBar: AppBar(title: const Text('Loại nghỉ phép'), backgroundColor: _primary, foregroundColor: Colors.white),
      floatingActionButton: PermissionGate(
        code: 'leavetype.manage',
        child: FloatingActionButton.extended(
          onPressed: () => showLeaveTypeForm(context),
          backgroundColor: _primary,
          foregroundColor: Colors.white,
          icon: const Icon(Icons.add),
          label: const Text('Thêm loại nghỉ'),
        ),
      ),
      body: _content(context, p),
    );
  }

  Widget _content(BuildContext context, AdminLeaveTypesProvider p) {
    if (p.isLoading && !p.loaded) return const LoadingView();
    if (p.error != null && !p.loaded) return ErrorView(message: p.error!, onRetry: p.load);
    return RefreshIndicator(
      onRefresh: p.load,
      child: p.items.isEmpty
          ? ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: const [Padding(padding: EdgeInsets.only(top: 80), child: EmptyView(message: 'Chưa có loại nghỉ phép.'))],
            )
          : ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              // Chừa chỗ dưới cho nút nổi.
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 88),
              itemCount: p.items.length,
              itemBuilder: (_, i) => _LeaveTypeCard(item: p.items[i]),
            ),
    );
  }
}

class _LeaveTypeCard extends StatelessWidget {
  final LeaveTypeAdmin item;

  const _LeaveTypeCard({required this.item});

  Future<void> _toggle(BuildContext context, bool value) async {
    // Chỉ hỏi xác nhận khi tắt.
    if (!value) {
      final ok = await confirmDialog(
        context,
        title: 'Tắt loại nghỉ',
        message: 'Tắt "${item.leaveTypeName}"? Nhân viên sẽ không chọn được loại nghỉ này khi xin nghỉ.',
        confirmText: 'Tắt',
      );
      if (!ok || !context.mounted) return;
    }
    final err = await context.read<AdminLeaveTypesProvider>().setActive(item, value);
    if (!context.mounted) return;
    showMessage(context, err ?? (value ? 'Đã bật loại nghỉ.' : 'Đã tắt loại nghỉ.'), error: err != null);
  }

  Future<void> _delete(BuildContext context) async {
    final ok = await confirmDialog(
      context,
      title: 'Xoá loại nghỉ',
      message: 'Xoá "${item.leaveTypeName}" (${item.leaveTypeCode})? Thao tác này không hoàn tác được.',
      confirmText: 'Xoá',
      danger: true,
    );
    if (!ok || !context.mounted) return;
    final err = await context.read<AdminLeaveTypesProvider>().delete(item);
    if (!context.mounted) return;
    // Backend từ chối khi đã có đơn/số dư: hiện nguyên văn và gợi ý tắt thay vì xoá.
    showMessage(context, err == null ? 'Đã xoá loại nghỉ.' : '$err\nBạn có thể tắt loại nghỉ thay vì xoá.', error: err != null);
  }

  @override
  Widget build(BuildContext context) {
    final desc = item.description;
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10), side: BorderSide(color: Colors.grey.shade200)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Expanded(child: Text(item.leaveTypeName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15))),
              StatusChip(label: item.isActive ? 'Đang dùng' : 'Đã tắt', color: item.isActive ? StatusChip.success : StatusChip.danger),
            ]),
            const SizedBox(height: 4),
            Text('Mã: ${item.leaveTypeCode}', style: const TextStyle(fontSize: 13)),
            const SizedBox(height: 2),
            Text(item.ruleText, style: TextStyle(fontSize: 13, color: Colors.grey.shade800)),
            const SizedBox(height: 6),
            Wrap(spacing: 6, runSpacing: 4, children: [
              StatusChip(label: 'Đơn vị: ${LeaveTypeAdmin.unitLabels[item.accrualUnit] ?? item.accrualUnit}', color: StatusChip.info),
              StatusChip(label: item.isPaid ? 'Có lương' : 'Không lương', color: item.isPaid ? StatusChip.success : StatusChip.warning),
            ]),
            if (desc != null && desc.isNotEmpty)
              Padding(padding: const EdgeInsets.only(top: 6), child: Text(desc, style: TextStyle(fontSize: 12, color: Colors.grey.shade600))),
            PermissionGate(
              code: 'leavetype.manage',
              child: Row(children: [
                Switch(value: item.isActive, onChanged: (v) => _toggle(context, v)),
                Text(item.isActive ? 'Bật' : 'Tắt', style: const TextStyle(fontSize: 13)),
                const Spacer(),
                IconButton(
                  tooltip: 'Sửa',
                  icon: const Icon(Icons.edit_outlined, color: _primary),
                  onPressed: () => showLeaveTypeForm(context, editing: item),
                ),
                IconButton(
                  tooltip: 'Xoá',
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  onPressed: () => _delete(context),
                ),
              ]),
            ),
          ],
        ),
      ),
    );
  }
}
