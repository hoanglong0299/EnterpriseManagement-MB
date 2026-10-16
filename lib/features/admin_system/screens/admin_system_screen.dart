import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/network/api_client.dart';
import '../../../services/system_admin_service.dart';
import '../../../shared/widgets/state_views.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/system_provider.dart';
import '../widgets/system_menus_tab.dart';
import '../widgets/system_permissions_tab.dart';
import '../widgets/system_roles_tab.dart';

// Quản trị hệ thống: 3 phần (vai trò, permission, menu), mỗi phần hiện theo permission *.manage.
// Loại nghỉ phép đã tách thành màn hình riêng /admin/leave-types.
class AdminSystemScreen extends StatelessWidget {
  const AdminSystemScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final tabs = <_SystemTab>[
      if (auth.can('role.manage')) _SystemTab('Vai trò', (p) => p.loadRoles(), const SystemRolesTab()),
      if (auth.can('permission.manage')) _SystemTab('Quyền', (p) => p.loadPermissions(), const SystemPermissionsTab()),
      if (auth.can('menu.manage')) _SystemTab('Menu', (p) => p.loadMenus(), const SystemMenusTab()),
    ];

    if (tabs.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Quản trị hệ thống'),
          backgroundColor: const Color(0xFF5A3FD8),
          foregroundColor: Colors.white,
        ),
        body: const EmptyView(message: 'Bạn không có quyền quản trị hệ thống.', icon: Icons.lock_outline),
      );
    }

    return ChangeNotifierProvider(
      create: (ctx) {
        final provider = SystemProvider(SystemAdminService(ctx.read<ApiClient>()));
        // Tải dữ liệu từng phần mà tài khoản được xem.
        for (final t in tabs) {
          t.load(provider);
        }
        return provider;
      },
      child: DefaultTabController(
        length: tabs.length,
        child: Scaffold(
          backgroundColor: const Color(0xFFF6F4FC),
          appBar: AppBar(
            title: const Text('Quản trị hệ thống'),
            backgroundColor: const Color(0xFF5A3FD8),
            foregroundColor: Colors.white,
            bottom: TabBar(
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white70,
              indicatorColor: Colors.white,
              tabs: tabs.map((t) => Tab(text: t.title)).toList(),
            ),
          ),
          body: TabBarView(children: tabs.map((t) => t.body).toList()),
        ),
      ),
    );
  }
}

class _SystemTab {
  final String title;
  final Future<void> Function(SystemProvider) load;
  final Widget body;

  _SystemTab(this.title, this.load, this.body);
}
