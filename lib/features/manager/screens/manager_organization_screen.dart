import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/network/api_client.dart';
import '../../../models/manager_organization.dart';
import '../../../services/manager_service.dart';
import '../../../shared/widgets/state_views.dart';
import '../../../shared/widgets/status_chip.dart';
import '../manager_helpers.dart';

// Phòng ban & chức vụ (tương ứng ManagerOrganizationPage), chỉ xem.
class ManagerOrganizationScreen extends StatelessWidget {
  const ManagerOrganizationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (ctx) => _OrganizationProvider(ManagerService(ctx.read<ApiClient>()))..load(),
      child: const _OrganizationView(),
    );
  }
}

class _OrganizationProvider extends ChangeNotifier {
  final ManagerService _service;

  _OrganizationProvider(this._service);

  List<ManagerDepartment> departments = [];
  List<ManagerPosition> positions = [];
  bool isLoading = false;
  String? errorMessage;

  Future<void> load() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();
    try {
      final results = await Future.wait([_service.getDepartments(), _service.getPositions()]);
      departments = results[0] as List<ManagerDepartment>;
      positions = results[1] as List<ManagerPosition>;
    } catch (e) {
      errorMessage = e.toString().replaceFirst('Exception: ', '');
    }
    isLoading = false;
    notifyListeners();
  }
}

class _OrganizationView extends StatelessWidget {
  const _OrganizationView();

  @override
  Widget build(BuildContext context) {
    final p = context.watch<_OrganizationProvider>();
    final loaded = p.departments.isNotEmpty || p.positions.isNotEmpty;

    Widget body;
    if (p.isLoading && !loaded) {
      body = const LoadingView();
    } else if (p.errorMessage != null && !loaded) {
      body = ErrorView(message: p.errorMessage!, onRetry: p.load);
    } else {
      body = DefaultTabController(
        length: 2,
        child: Column(
          children: [
            Container(
              color: Colors.white,
              child: TabBar(
                labelColor: managerPrimary,
                indicatorColor: managerPrimary,
                tabs: [
                  Tab(text: 'Phòng ban (${p.departments.length})'),
                  Tab(text: 'Chức vụ (${p.positions.length})'),
                ],
              ),
            ),
            Expanded(
              child: TabBarView(
                children: [
                  _list(
                    p.load,
                    p.departments.length,
                    (i) {
                      final d = p.departments[i];
                      return _Row(
                        title: d.departmentName,
                        subtitle: d.managerName ?? 'Chưa có quản lý',
                        active: d.isActive,
                      );
                    },
                  ),
                  _list(
                    p.load,
                    p.positions.length,
                    (i) {
                      final pos = p.positions[i];
                      return _Row(title: pos.positionName, subtitle: pos.description ?? '--', active: pos.isActive);
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      backgroundColor: managerBackground,
      appBar: managerAppBar('Phòng ban & chức vụ'),
      body: body,
    );
  }

  Widget _list(Future<void> Function() onRefresh, int count, Widget Function(int) item) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: count == 0
          ? ListView(children: const [SizedBox(height: 80), EmptyView(message: 'Chưa có dữ liệu.')])
          : ListView.separated(
              padding: const EdgeInsets.all(12),
              itemCount: count,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (_, i) => item(i),
            ),
    );
  }
}

class _Row extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool active;

  const _Row({required this.title, required this.subtitle, required this.active});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
                  Text(subtitle, style: const TextStyle(color: Colors.black54, fontSize: 13)),
                ],
              ),
            ),
            StatusChip(label: active ? 'Hoạt động' : 'Ngừng', color: active ? StatusChip.success : StatusChip.neutral),
          ],
        ),
      ),
    );
  }
}
