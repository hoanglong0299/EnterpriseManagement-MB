import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../models/system_permission.dart';
import '../providers/system_provider.dart';

// Nhãn nhóm giống bản web; module lạ thì hiện nguyên mã module.
const Map<String, String> _groupLabels = {
  'dashboard': 'Dashboard',
  'attendance': 'Chấm công',
  'leave': 'Nghỉ phép',
  'organization': 'Phòng ban & chức vụ',
  'employee': 'Nhân viên',
  'users': 'Tài khoản đăng nhập',
  'audit': 'Audit Log',
  'system': 'System Administration',
};

const Map<String, String> _scopeLabels = {'employee': 'Nhân viên', 'manager': 'Manager', 'admin': 'Admin'};

class _Group {
  final String key;
  final List<SystemPermission> pages = [];
  final List<SystemPermission> actions = [];

  _Group(this.key);

  String get label => _groupLabels[key] ?? key;
}

// Gom permission theo tính năng: "page.*" (quyền thấy menu) và quyền hành động cùng nhóm, như bản web.
List<_Group> _buildGroups(List<SystemPermission> permissions) {
  final map = <String, _Group>{};
  for (final p in permissions) {
    if (p.module == 'page') {
      final last = p.permissionCode.split('.').last;
      final key = last == 'employees' ? 'employee' : last;
      map.putIfAbsent(key, () => _Group(key)).pages.add(p);
    } else {
      map.putIfAbsent(p.module, () => _Group(p.module)).actions.add(p);
    }
  }
  return map.values.toList()..sort((a, b) => a.label.compareTo(b.label));
}

String _pageLabel(SystemPermission p) {
  final segs = p.permissionCode.split('.');
  final scope = segs.length == 3 ? _scopeLabels[segs[1]] : null;
  return scope == null ? p.permissionName : '${p.permissionName} ($scope)';
}

// Danh sách checkbox permission theo nhóm (dùng khi gán quyền cho vai trò / menu).
class PermissionPicker extends StatelessWidget {
  final Set<String> selected;
  final ValueChanged<Set<String>> onChanged;

  const PermissionPicker({super.key, required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<SystemProvider>().permissions;
    if (state.loading && !state.loaded) {
      return const Padding(padding: EdgeInsets.all(16), child: Center(child: CircularProgressIndicator()));
    }
    if (state.error != null && !state.loaded) {
      return Padding(
        padding: const EdgeInsets.all(8),
        child: Text('Không tải được danh sách permission: ${state.error}', style: const TextStyle(color: Colors.red)),
      );
    }
    final groups = _buildGroups(state.items);
    if (groups.isEmpty) return const Padding(padding: EdgeInsets.all(8), child: Text('Chưa có permission nào.'));

    void toggle(String code, bool on) {
      final next = {...selected};
      on ? next.add(code) : next.remove(code);
      onChanged(next);
    }

    Widget tile(SystemPermission p, String label) => CheckboxListTile(
          dense: true,
          contentPadding: EdgeInsets.zero,
          controlAffinity: ListTileControlAffinity.leading,
          title: Text(label),
          subtitle: Text(p.permissionCode, style: const TextStyle(fontSize: 11)),
          value: selected.contains(p.permissionCode),
          onChanged: (v) => toggle(p.permissionCode, v ?? false),
        );

    return Column(
      children: groups.map((g) {
        final count = [...g.pages, ...g.actions].where((p) => selected.contains(p.permissionCode)).length;
        return ExpansionTile(
          tilePadding: EdgeInsets.zero,
          childrenPadding: const EdgeInsets.only(left: 4),
          title: Text(g.label, style: const TextStyle(fontWeight: FontWeight.w600)),
          trailing: count > 0 ? CircleAvatar(radius: 11, child: Text('$count', style: const TextStyle(fontSize: 11))) : null,
          children: [
            if (g.pages.isNotEmpty) const Align(alignment: Alignment.centerLeft, child: Text('Xem menu', style: TextStyle(fontSize: 12, color: Colors.grey))),
            ...g.pages.map((p) => tile(p, _pageLabel(p))),
            if (g.actions.isNotEmpty) const Align(alignment: Alignment.centerLeft, child: Text('Hành động trong trang', style: TextStyle(fontSize: 12, color: Colors.grey))),
            ...g.actions.map((p) => tile(p, p.permissionName)),
          ],
        );
      }).toList(),
    );
  }
}
