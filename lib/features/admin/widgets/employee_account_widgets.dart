import 'package:flutter/material.dart';

import '../../../core/utils/helpers.dart';
import '../../../models/admin_employee.dart';
import '../../../shared/widgets/status_chip.dart';
import 'admin_common.dart';

// Kiểm tra tên đăng nhập: 3-50 ký tự gồm chữ, số, '.', '_', '-'. Trả về null nếu hợp lệ.
String? validateUsername(String value) {
  final v = value.trim();
  if (v.isEmpty) return 'Vui lòng nhập tên đăng nhập.';
  if (!RegExp(r'^[A-Za-z0-9._-]{3,50}$').hasMatch(v)) {
    return 'Tên đăng nhập gồm 3-50 ký tự: chữ, số, dấu chấm, gạch dưới hoặc gạch ngang.';
  }
  return null;
}

// Kiểm tra email đơn giản. Trả về null nếu hợp lệ.
String? validateEmail(String value) {
  final v = value.trim();
  if (v.isEmpty) return 'Vui lòng nhập email.';
  if (!RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(v)) return 'Email không đúng định dạng.';
  return null;
}

Color employmentStatusColor(String s) => switch (s) {
  'Active' => StatusChip.success,
  'Probation' => StatusChip.warning,
  'Resigned' || 'Terminated' => StatusChip.danger,
  _ => StatusChip.neutral,
};

// Chọn nhiều vai trò bằng các chip tự xuống dòng.
class RoleChips extends StatelessWidget {
  final List<AdminRole> roles;
  final Set<String> selected;
  final ValueChanged<String> onToggle;

  const RoleChips({super.key, required this.roles, required this.selected, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 4,
      children: [
        for (final r in roles)
          FilterChip(
            label: Text(r.roleName),
            selected: selected.contains(r.roleCode),
            onSelected: (_) => onToggle(r.roleCode),
          ),
      ],
    );
  }
}

// Thẻ nhân viên trong danh sách: hồ sơ + tài khoản + các thao tác.
class AdminEmployeeCard extends StatelessWidget {
  final AdminEmployee employee;
  final String managerName;
  final bool canManageEmployee;
  final bool canManageAccount;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onToggleEmployment;
  final VoidCallback? onResetPassword;
  final VoidCallback? onToggleAccount;

  const AdminEmployeeCard({
    super.key,
    required this.employee,
    this.managerName = '',
    this.canManageEmployee = false,
    this.canManageAccount = false,
    this.onTap,
    this.onEdit,
    this.onToggleEmployment,
    this.onResetPassword,
    this.onToggleAccount,
  });

  @override
  Widget build(BuildContext context) {
    final e = employee;
    return Card(
      margin: EdgeInsets.zero,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(e.fullName, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: StatusChip(
                      label: employmentStatusLabel(e.employmentStatus),
                      color: employmentStatusColor(e.employmentStatus),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              InfoLine('Mã NV', e.employeeCode),
              InfoLine('Tên đăng nhập', e.username),
              InfoLine('Vai trò', e.roleNames.isNotEmpty ? e.roleNames.join(', ') : e.roleCodes.join(', ')),
              InfoLine('Phòng ban', e.departmentName),
              InfoLine('Chức vụ', e.positionName),
              InfoLine('Quản lý', managerName),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    StatusChip(
                      label: e.isAccountActive ? 'Tài khoản hoạt động' : 'Tài khoản đã khoá',
                      color: e.isAccountActive ? StatusChip.success : StatusChip.danger,
                    ),
                    if (e.lastLoginAt != null)
                      Text(
                        'Đăng nhập cuối: ${formatDateTime(e.lastLoginAt)}',
                        style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                      ),
                  ],
                ),
              ),
              if (canManageEmployee || canManageAccount)
                Wrap(
                  alignment: WrapAlignment.end,
                  children: [
                    if (canManageEmployee) TextButton(onPressed: onEdit, child: const Text('Sửa')),
                    if (canManageAccount)
                      TextButton(onPressed: onResetPassword, child: const Text('Đặt lại mật khẩu')),
                    if (canManageAccount)
                      TextButton(
                        onPressed: onToggleAccount,
                        child: Text(e.isAccountActive ? 'Khoá tài khoản' : 'Mở tài khoản'),
                      ),
                    if (canManageEmployee)
                      TextButton(
                        onPressed: onToggleEmployment,
                        child: Text(e.isActive ? 'Cho nghỉ việc' : 'Phục hồi'),
                      ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}
