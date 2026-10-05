import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../models/system_role.dart';
import '../../../shared/widgets/confirm_dialog.dart';
import '../../../shared/widgets/permission_gate.dart';
import '../../../shared/widgets/status_chip.dart';
import '../providers/system_provider.dart';
import 'permission_picker.dart';
import 'system_common.dart';

// Tab Vai trò (role.manage): danh sách, tạo/sửa, khoá/mở, gán permission.
class SystemRolesTab extends StatelessWidget {
  const SystemRolesTab({super.key});

  Future<void> _toggle(BuildContext context, SystemRole r) async {
    final lock = r.isActive;
    final ok = await confirmDialog(
      context,
      title: lock ? 'Khoá vai trò?' : 'Mở vai trò?',
      message: '${lock ? 'Khoá' : 'Mở'} vai trò "${r.roleName}" (${r.roleCode})?',
      danger: lock,
    );
    if (!ok || !context.mounted) return;
    await runWrite(context, () => context.read<SystemProvider>().setRoleActive(r, !r.isActive), lock ? 'Đã khoá vai trò.' : 'Đã mở vai trò.');
  }

  @override
  Widget build(BuildContext context) {
    final p = context.watch<SystemProvider>();
    return SystemSectionList<SystemRole>(
      state: p.roles,
      onReload: p.loadRoles,
      emptyMessage: 'Chưa có vai trò. Tạo vai trò để gán permission cho tài khoản.',
      header: PermissionGate(
        code: 'role.manage',
        child: Align(
          alignment: Alignment.centerRight,
          child: FilledButton.icon(
            onPressed: () => showFormSheet(context, (_) => const _RoleForm()),
            icon: const Icon(Icons.add),
            label: const Text('Tạo vai trò'),
            style: FilledButton.styleFrom(backgroundColor: systemPrimary),
          ),
        ),
      ),
      itemBuilder: (r) => SystemCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Expanded(child: Text(r.roleName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15))),
              StatusChip(label: r.isActive ? 'Đang hoạt động' : 'Đã khoá', color: r.isActive ? StatusChip.success : StatusChip.danger),
            ]),
            const SizedBox(height: 4),
            Text('Mã: ${r.roleCode}', style: const TextStyle(fontSize: 13)),
            if ((r.description ?? '').isNotEmpty) Text(r.description!, style: TextStyle(fontSize: 13, color: Colors.grey.shade700)),
            Text('${r.permissions.length} quyền', style: TextStyle(fontSize: 13, color: Colors.grey.shade700)),
            PermissionGate(
              code: 'role.manage',
              child: Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                TextButton.icon(
                  onPressed: () => showFormSheet(context, (_) => _RoleForm(editing: r)),
                  icon: const Icon(Icons.edit, size: 18),
                  label: const Text('Sửa / gán quyền'),
                ),
                TextButton(
                  onPressed: () => _toggle(context, r),
                  child: Text(r.isActive ? 'Khoá' : 'Mở', style: TextStyle(color: r.isActive ? Colors.red : null)),
                ),
              ]),
            ),
          ],
        ),
      ),
    );
  }
}

class _RoleForm extends StatefulWidget {
  final SystemRole? editing;

  const _RoleForm({this.editing});

  @override
  State<_RoleForm> createState() => _RoleFormState();
}

class _RoleFormState extends State<_RoleForm> {
  late final TextEditingController _code = TextEditingController(text: widget.editing?.roleCode ?? '');
  late final TextEditingController _name = TextEditingController(text: widget.editing?.roleName ?? '');
  late final TextEditingController _desc = TextEditingController(text: widget.editing?.description ?? '');
  late Set<String> _selected = {...?widget.editing?.permissions};
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    // Danh sách permission cần quyền permission.manage; nếu không tải được, form hiện lỗi.
    WidgetsBinding.instance.addPostFrameCallback((_) => context.read<SystemProvider>().ensurePermissions());
  }

  @override
  void dispose() {
    _code.dispose();
    _name.dispose();
    _desc.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_code.text.trim().isEmpty || _name.text.trim().isEmpty) {
      showMessage(context, 'Vui lòng nhập mã role và tên role.', error: true);
      return;
    }
    setState(() => _saving = true);
    final editing = widget.editing;
    final ok = await runWrite(
      context,
      () => context.read<SystemProvider>().saveRole(
            editing: editing,
            code: _code.text.trim(),
            name: _name.text.trim(),
            description: _desc.text.trim().isEmpty ? null : _desc.text.trim(),
            permissionCodes: _selected.toList(),
          ),
      editing == null ? 'Đã tạo vai trò.' : 'Đã cập nhật vai trò.',
    );
    if (!mounted) return;
    if (ok) {
      Navigator.pop(context);
    } else {
      setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SystemFormFrame(
      title: widget.editing == null ? 'Tạo vai trò' : 'Sửa vai trò',
      saving: _saving,
      onSave: _save,
      children: [
        TextField(controller: _code, enabled: widget.editing == null, decoration: systemInput('Mã role *')),
        const SizedBox(height: 12),
        TextField(controller: _name, decoration: systemInput('Tên role *')),
        const SizedBox(height: 12),
        TextField(controller: _desc, maxLines: 2, decoration: systemInput('Mô tả')),
        const SizedBox(height: 16),
        const Text('Menu & Permission', style: TextStyle(fontWeight: FontWeight.bold)),
        PermissionPicker(selected: _selected, onChanged: (v) => setState(() => _selected = v)),
      ],
    );
  }
}
