import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../models/system_permission.dart';
import '../providers/system_provider.dart';
import 'permission_groups.dart';

// Chọn quyền theo nhóm chức năng (Nhân viên cơ bản, Quản lý, HR, Admin) khi gán quyền cho vai trò / menu.
// Tick ô đầu nhóm là chọn cả nhóm; mỗi nhóm chia "Menu hiển thị" và "Chức năng", mỗi phần cũng có ô tick riêng.
class PermissionPicker extends StatefulWidget {
  final Set<String> selected;
  final ValueChanged<Set<String>> onChanged;

  const PermissionPicker({super.key, required this.selected, required this.onChanged});

  @override
  State<PermissionPicker> createState() => _PermissionPickerState();
}

class _PermissionPickerState extends State<PermissionPicker> {
  String _query = '';

  bool _matches(SystemPermission p) {
    final q = _query.trim().toLowerCase();
    return q.isEmpty || p.permissionName.toLowerCase().contains(q) || p.permissionCode.toLowerCase().contains(q);
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<SystemProvider>().permissions;
    if (state.loading && !state.loaded) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (state.error != null && !state.loaded) {
      return Padding(
        padding: const EdgeInsets.all(8),
        child: Text('Không tải được danh sách quyền: ${state.error}', style: const TextStyle(color: Colors.red)),
      );
    }
    final groups = buildPermissionGroups(state.items);
    if (groups.isEmpty) return const Padding(padding: EdgeInsets.all(8), child: Text('Chưa có quyền nào.'));

    final selected = widget.selected;
    final searching = _query.trim().isNotEmpty;
    final visibleGroups = groups.where((g) => g.all.any(_matches)).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          decoration: const InputDecoration(
            isDense: true,
            prefixIcon: Icon(Icons.search),
            hintText: 'Tìm menu hoặc quyền...',
            border: OutlineInputBorder(),
          ),
          onChanged: (v) => setState(() => _query = v),
        ),
        const SizedBox(height: 8),
        if (visibleGroups.isEmpty)
          Padding(padding: const EdgeInsets.all(8), child: Text('Không có menu hoặc quyền nào khớp "$_query".')),
        for (final g in visibleGroups) _groupTile(g, selected, searching),
      ],
    );
  }

  Widget _groupTile(PermissionGroup g, Set<String> selected, bool searching) {
    final all = g.all;
    final count = all.where((p) => selected.contains(p.permissionCode)).length;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: count > 0 ? const Color(0xFFB9A9F5) : Colors.black12),
      ),
      child: ExpansionTile(
        // Đổi key khi bắt đầu/ngừng tìm kiếm để nhóm tự mở khi có kết quả.
        key: PageStorageKey('${g.key}-$searching'),
        initiallyExpanded: searching,
        shape: const Border(),
        collapsedShape: const Border(),
        tilePadding: const EdgeInsets.only(left: 4, right: 12),
        childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
        leading: Checkbox(
          tristate: true,
          value: triState(all, selected),
          onChanged: (_) => widget.onChanged(toggleMany(all, selected)),
        ),
        title: Text(g.label, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
        subtitle: Text(g.hint, style: const TextStyle(fontSize: 12, color: Colors.black54)),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: count > 0 ? const Color(0xFFEFEBFF) : Colors.black12,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            '$count/${all.length}',
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: count > 0 ? const Color(0xFF5A3FD8) : Colors.black54),
          ),
        ),
        children: [
          _section('Menu hiển thị (các trang)', g.menus, selected),
          _section('Chức năng (hành động trong trang)', g.actions, selected),
        ],
      ),
    );
  }

  Widget _section(String title, List<SystemPermission> items, Set<String> selected) {
    final visible = items.where(_matches).toList();
    if (visible.isEmpty) return const SizedBox.shrink();
    final done = items.where((p) => selected.contains(p.permissionCode)).length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CheckboxListTile(
          dense: true,
          contentPadding: EdgeInsets.zero,
          controlAffinity: ListTileControlAffinity.leading,
          tristate: true,
          title: Text('$title ($done/${items.length})', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
          value: triState(items, selected),
          onChanged: (_) => widget.onChanged(toggleMany(items, selected)),
        ),
        for (final p in visible)
          Padding(
            padding: const EdgeInsets.only(left: 24),
            child: CheckboxListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
              title: Text(p.permissionName),
              subtitle: Text(p.permissionCode, style: const TextStyle(fontSize: 11)),
              value: selected.contains(p.permissionCode),
              onChanged: (v) {
                final next = {...selected};
                (v ?? false) ? next.add(p.permissionCode) : next.remove(p.permissionCode);
                widget.onChanged(next);
              },
            ),
          ),
      ],
    );
  }
}
