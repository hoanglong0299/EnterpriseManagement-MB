import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../models/system_menu.dart';
import '../../../shared/widgets/confirm_dialog.dart';
import '../../../shared/widgets/permission_gate.dart';
import '../../../shared/widgets/status_chip.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/system_provider.dart';
import 'permission_picker.dart';
import 'system_common.dart';

// Tab Menu (menu.manage): danh sách, tạo/sửa, ẩn/hiện, bật/tắt, gán permission.
class SystemMenusTab extends StatelessWidget {
  const SystemMenusTab({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.watch<SystemProvider>();
    final canManage = context.watch<AuthProvider>().can('menu.manage');
    return SystemSectionList<SystemMenu>(
      state: p.menus,
      onReload: p.loadMenus,
      emptyMessage: 'Chưa có menu. Tạo menu để backend điều khiển điều hướng theo quyền.',
      header: PermissionGate(
        code: 'menu.manage',
        child: Align(
          alignment: Alignment.centerRight,
          child: FilledButton.icon(
            onPressed: () => showFormSheet(context, (_) => const _MenuForm()),
            icon: const Icon(Icons.add),
            label: const Text('Tạo menu'),
            style: FilledButton.styleFrom(backgroundColor: systemPrimary),
          ),
        ),
      ),
      itemBuilder: (m) => SystemCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Expanded(child: Text(m.menuName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15))),
              Text('#${m.displayOrder}', style: TextStyle(color: Colors.grey.shade600)),
            ]),
            const SizedBox(height: 4),
            Text('Mã: ${m.menuCode}', style: const TextStyle(fontSize: 13)),
            Text('Route: ${m.route}', style: const TextStyle(fontSize: 13)),
            Text('Permission: ${m.permissions.isEmpty ? '--' : m.permissions.join(', ')}', style: TextStyle(fontSize: 12, color: Colors.grey.shade700)),
            const SizedBox(height: 6),
            Wrap(spacing: 8, children: [
              StatusChip(label: m.isVisible ? 'Hiện' : 'Ẩn', color: m.isVisible ? StatusChip.info : StatusChip.neutral),
              StatusChip(label: m.isActive ? 'Đang hoạt động' : 'Đã tắt', color: m.isActive ? StatusChip.success : StatusChip.danger),
            ]),
            // Công tắc và nút sửa chỉ hiện với người có quyền menu.manage.
            if (canManage) ...[
              Row(children: [
                const Text('Hiện menu', style: TextStyle(fontSize: 13)),
                Switch(
                  value: m.isVisible,
                  onChanged: (v) => runWrite(context, () => context.read<SystemProvider>().setMenuVisible(m, v), v ? 'Đã hiện menu.' : 'Đã ẩn menu.'),
                ),
                const Spacer(),
                const Text('Hoạt động', style: TextStyle(fontSize: 13)),
                Switch(
                  value: m.isActive,
                  onChanged: (v) async {
                    if (!v) {
                      final ok = await confirmDialog(context, title: 'Tắt menu?', message: 'Tắt menu "${m.menuName}"?', danger: true);
                      if (!ok || !context.mounted) return;
                    }
                    await runWrite(context, () => context.read<SystemProvider>().setMenuActive(m, v), v ? 'Đã bật menu.' : 'Đã tắt menu.');
                  },
                ),
              ]),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: () => showFormSheet(context, (_) => _MenuForm(editing: m)),
                  icon: const Icon(Icons.edit, size: 18),
                  label: const Text('Sửa / gán quyền'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _MenuForm extends StatefulWidget {
  final SystemMenu? editing;

  const _MenuForm({this.editing});

  @override
  State<_MenuForm> createState() => _MenuFormState();
}

class _MenuFormState extends State<_MenuForm> {
  late final TextEditingController _code = TextEditingController(text: widget.editing?.menuCode ?? '');
  late final TextEditingController _name = TextEditingController(text: widget.editing?.menuName ?? '');
  late final TextEditingController _icon = TextEditingController(text: widget.editing?.icon ?? '');
  late final TextEditingController _route = TextEditingController(text: widget.editing?.route ?? '');
  late final TextEditingController _order = TextEditingController(text: '${widget.editing?.displayOrder ?? 1}');
  late Set<String> _selected = {...?widget.editing?.permissions};
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => context.read<SystemProvider>().ensurePermissions());
  }

  @override
  void dispose() {
    _code.dispose();
    _name.dispose();
    _icon.dispose();
    _route.dispose();
    _order.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_code.text.trim().isEmpty || _name.text.trim().isEmpty || _route.text.trim().isEmpty) {
      showMessage(context, 'Vui lòng nhập mã menu, tên menu và route.', error: true);
      return;
    }
    if (_route.text.trim() == SystemProvider.hiddenMenuRoute) {
      showMessage(context, 'Không cấu hình URL đăng nhập admin ẩn trong menu.', error: true);
      return;
    }
    final order = int.tryParse(_order.text.trim());
    if (order == null) {
      showMessage(context, 'Thứ tự phải là số nguyên.', error: true);
      return;
    }
    setState(() => _saving = true);
    final editing = widget.editing;
    final ok = await runWrite(
      context,
      () => context.read<SystemProvider>().saveMenu(
            editing: editing,
            code: _code.text.trim(),
            name: _name.text.trim(),
            icon: _icon.text.trim().isEmpty ? null : _icon.text.trim(),
            route: _route.text.trim(),
            displayOrder: order,
            permissionCodes: _selected.toList(),
          ),
      editing == null ? 'Đã tạo menu.' : 'Đã cập nhật menu.',
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
      title: widget.editing == null ? 'Tạo menu' : 'Sửa menu',
      saving: _saving,
      onSave: _save,
      children: [
        TextField(controller: _code, enabled: widget.editing == null, decoration: systemInput('Mã menu *')),
        const SizedBox(height: 12),
        TextField(controller: _name, decoration: systemInput('Tên menu *')),
        const SizedBox(height: 12),
        TextField(controller: _route, decoration: systemInput('Route *', hint: 'vd: /admin/users')),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(child: TextField(controller: _icon, decoration: systemInput('Icon'))),
          const SizedBox(width: 12),
          SizedBox(
            width: 100,
            child: TextField(controller: _order, keyboardType: TextInputType.number, decoration: systemInput('Thứ tự')),
          ),
        ]),
        const SizedBox(height: 16),
        const Text('Permission được thấy menu này', style: TextStyle(fontWeight: FontWeight.bold)),
        PermissionPicker(selected: _selected, onChanged: (v) => setState(() => _selected = v)),
      ],
    );
  }
}
