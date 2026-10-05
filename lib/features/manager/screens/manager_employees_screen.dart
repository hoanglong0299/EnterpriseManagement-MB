import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/network/api_client.dart';
import '../../../core/utils/helpers.dart';
import '../../../models/manager_employee.dart';
import '../../../services/manager_service.dart';
import '../../../shared/widgets/state_views.dart';
import '../../../shared/widgets/status_chip.dart';
import '../../auth/providers/auth_provider.dart';
import '../manager_helpers.dart';
import '../providers/manager_employees_provider.dart';

// Nhân viên của tôi (tương ứng ManagerEmployeesPage): toàn bộ cấp dưới kể cả cấp dưới của cấp dưới, chỉ xem.
class ManagerEmployeesScreen extends StatelessWidget {
  const ManagerEmployeesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (ctx) => ManagerEmployeesProvider(
        ManagerService(ctx.read<ApiClient>()),
        ctx.read<AuthProvider>(),
      )..load(),
      child: const _ManagerEmployeesView(),
    );
  }
}

class _ManagerEmployeesView extends StatelessWidget {
  const _ManagerEmployeesView();

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ManagerEmployeesProvider>();
    final list = provider.filtered;

    Widget body;
    if (provider.isLoading && provider.employees.isEmpty) {
      body = const LoadingView();
    } else if (provider.errorMessage != null && provider.employees.isEmpty) {
      body = ErrorView(message: provider.errorMessage!, onRetry: provider.load);
    } else if (provider.employees.isEmpty) {
      body = const EmptyView(message: 'Team của bạn chưa có nhân viên nào.', icon: Icons.groups_outlined);
    } else {
      body = Column(
        children: [
          _FilterBar(provider: provider),
          Expanded(
            child: RefreshIndicator(
              onRefresh: provider.load,
              child: list.isEmpty
                  ? ListView(children: const [SizedBox(height: 80), EmptyView(message: 'Không có nhân viên phù hợp.', icon: Icons.search_off)])
                  : ListView.separated(
                      padding: const EdgeInsets.all(12),
                      itemCount: list.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 8),
                      itemBuilder: (_, i) => _EmployeeCard(employee: list[i]),
                    ),
            ),
          ),
        ],
      );
    }

    return Scaffold(
      backgroundColor: managerBackground,
      appBar: managerAppBar('Nhân viên của tôi'),
      body: body,
    );
  }
}

class _FilterBar extends StatelessWidget {
  final ManagerEmployeesProvider provider;

  const _FilterBar({required this.provider});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      child: Column(
        children: [
          TextField(
            onChanged: provider.setKeyword,
            decoration: InputDecoration(
              hintText: 'Tìm theo tên, mã NV, email, chức vụ',
              prefixIcon: const Icon(Icons.search),
              isDense: true,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String?>(
                  initialValue: provider.departmentFilter,
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: 'Phòng ban', isDense: true, border: OutlineInputBorder()),
                  items: [
                    const DropdownMenuItem<String?>(value: null, child: Text('Tất cả')),
                    ...provider.departments.map((d) => DropdownMenuItem<String?>(value: d, child: Text(d, overflow: TextOverflow.ellipsis))),
                  ],
                  onChanged: provider.setDepartment,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: DropdownButtonFormField<String?>(
                  initialValue: provider.statusFilter,
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: 'Trạng thái', isDense: true, border: OutlineInputBorder()),
                  items: [
                    const DropdownMenuItem<String?>(value: null, child: Text('Tất cả')),
                    ...provider.statuses.map((s) => DropdownMenuItem<String?>(value: s, child: Text(s))),
                  ],
                  onChanged: provider.setStatus,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _EmployeeCard extends StatelessWidget {
  final ManagerEmployee employee;

  const _EmployeeCard({required this.employee});

  @override
  Widget build(BuildContext context) {
    final e = employee;
    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _showDetail(context, e),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: managerPrimary.withValues(alpha: 0.12),
                child: Text(e.fullName.isEmpty ? '?' : e.fullName.trim().split(' ').last[0].toUpperCase(),
                    style: const TextStyle(color: managerPrimary, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(e.fullName, style: const TextStyle(fontWeight: FontWeight.w600)),
                    Text('${e.employeeCode} · ${e.positionName}', style: const TextStyle(color: Colors.black54, fontSize: 13)),
                    Text('${e.departmentName} · QL: ${e.managerName ?? '--'}', style: const TextStyle(color: Colors.black54, fontSize: 13)),
                  ],
                ),
              ),
              StatusChip(label: e.isActive ? 'Đang làm' : e.employmentStatus, color: e.isActive ? StatusChip.success : StatusChip.neutral),
            ],
          ),
        ),
      ),
    );
  }

  void _showDetail(BuildContext context, ManagerEmployee e) {
    Widget row(String label, String value) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(width: 120, child: Text(label, style: const TextStyle(color: Colors.black54))),
              Expanded(child: Text(value.isEmpty ? '--' : value)),
            ],
          ),
        );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (_) => SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(e.fullName, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              row('Mã NV', e.employeeCode),
              row('Chức vụ', e.positionName),
              row('Phòng ban', e.departmentName),
              row('Quản lý trực tiếp', e.managerName ?? ''),
              row('Email', e.email ?? ''),
              row('Điện thoại', e.phone ?? ''),
              row('Địa chỉ', e.address ?? ''),
              row('Ngày sinh', formatDate(e.dateOfBirth)),
              row('Giới tính', e.genderLabel),
              row('Ngày vào làm', formatDate(e.hireDate)),
              row('Trạng thái', e.employmentStatus),
            ],
          ),
        ),
      ),
    );
  }
}
