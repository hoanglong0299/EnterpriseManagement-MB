import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../models/system_permission.dart';
import '../../../shared/widgets/confirm_dialog.dart';
import '../../../shared/widgets/permission_gate.dart';
import '../../../shared/widgets/status_chip.dart';
import '../providers/system_provider.dart';
import 'system_common.dart';

// Tab Permission (permission.manage): danh mục permission, tạo/sửa, khoá/mở.
class SystemPermissionsTab extends StatelessWidget {
  const SystemPermissionsTab({super.key});

  Future<void> _toggle(BuildContext context, SystemPermission x) async {
    final lock = x.isActive;
    final ok = await confirmDialog(
      context,
      title: lock ? 'Khoá permission?' : 'Mở permission?',
      message: '${lock ? 'Khoá' : 'Mở'} permission "${x.permissionCode}"?',
      danger: lock,
    );
    if (!ok || !context.mounted) return;
    await runWrite(context, () => context.read<SystemProvider>().setPermissionActive(x, !x.isActive), lock ? 'Đã khoá permission.' : 'Đã mở permission.');
  }

  @override
  Widget build(BuildContext context) {
    final p = context.watch<SystemProvider>();
    return SystemSectionList<SystemPermission>(
      state: p.permissions,
      onReload: p.loadPermissions,
      emptyMessage: 'Chưa có permission. Tạo permission theo dạng module.action.',
      header: PermissionGate(
        code: 'permission.manage',
        child: Align(
          alignment: Alignment.centerRight,
          child: FilledButton.icon(
            onPressed: () => showFormSheet(context, (_) => const _PermissionForm()),
            icon: const Icon(Icons.add),
            label: const Text('Tạo permission'),
            style: FilledButton.styleFrom(backgroundColor: systemPrimary),
          ),
        ),
      ),
      itemBuilder: (x) => SystemCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Expanded(child: Text(x.permissionName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15))),
              StatusChip(label: x.isActive ? 'Đang hoạt động' : 'Đã khoá', color: x.isActive ? StatusChip.success : StatusChip.danger),
            ]),
            const SizedBox(height: 4),
            Text(x.permissionCode, style: const TextStyle(fontSize: 13)),
            Text('Module: ${x.module}', style: TextStyle(fontSize: 13, color: Colors.grey.shade700)),
            if ((x.description ?? '').isNotEmpty) Text(x.description!, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
            PermissionGate(
              code: 'permission.manage',
              child: Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                TextButton.icon(
                  onPressed: () => showFormSheet(context, (_) => _PermissionForm(editing: x)),
                  icon: const Icon(Icons.edit, size: 18),
                  label: const Text('Sửa'),
                ),
                TextButton(
                  onPressed: () => _toggle(context, x),
                  child: Text(x.isActive ? 'Khoá' : 'Mở', style: TextStyle(color: x.isActive ? Colors.red : null)),
                ),
              ]),
            ),
          ],
        ),
      ),
    );
  }
}

class _PermissionForm extends StatefulWidget {
  final SystemPermission? editing;

  const _PermissionForm({this.editing});

  @override
  State<_PermissionForm> createState() => _PermissionFormState();
}

class _PermissionFormState extends State<_PermissionForm> {
  late final TextEditingController _code = TextEditingController(text: widget.editing?.permissionCode ?? '');
  late final TextEditingController _name = TextEditingController(text: widget.editing?.permissionName ?? '');
  late final TextEditingController _module = TextEditingController(text: widget.editing?.module ?? '');
  late final TextEditingController _desc = TextEditingController(text: widget.editing?.description ?? '');
  bool _saving = false;

  @override
  void dispose() {
    _code.dispose();
    _name.dispose();
    _module.dispose();
    _desc.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final editing = widget.editing;
    // Giống web: mã phải có dạng module.action (chỉ chữ cái, ngăn cách bằng dấu chấm).
    if (editing == null && !RegExp(r'^[a-z]+(\.[a-z]+)+$', caseSensitive: false).hasMatch(_code.text.trim())) {
      showMessage(context, 'Permission code cần có dạng module.action.', error: true);
      return;
    }
    if (_name.text.trim().isEmpty || _module.text.trim().isEmpty) {
      showMessage(context, 'Vui lòng nhập tên permission và module.', error: true);
      return;
    }
    setState(() => _saving = true);
    final ok = await runWrite(
      context,
      () => context.read<SystemProvider>().savePermission(
            editing: editing,
            code: _code.text.trim(),
            name: _name.text.trim(),
            module: _module.text.trim(),
            description: _desc.text.trim().isEmpty ? null : _desc.text.trim(),
          ),
      editing == null ? 'Đã tạo permission.' : 'Đã cập nhật permission.',
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
      title: widget.editing == null ? 'Tạo permission' : 'Sửa permission',
      saving: _saving,
      onSave: _save,
      children: [
        TextField(controller: _code, enabled: widget.editing == null, decoration: systemInput('Permission code *', hint: 'vd: report.view')),
        const SizedBox(height: 12),
        TextField(controller: _name, decoration: systemInput('Tên permission *')),
        const SizedBox(height: 12),
        TextField(controller: _module, decoration: systemInput('Module *')),
        const SizedBox(height: 12),
        TextField(controller: _desc, maxLines: 2, decoration: systemInput('Mô tả')),
      ],
    );
  }
}
