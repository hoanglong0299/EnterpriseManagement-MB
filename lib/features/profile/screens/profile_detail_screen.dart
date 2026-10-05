import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../models/employee.dart';
import '../../../shared/widgets/confirm_dialog.dart';
import '../../../shared/widgets/permission_gate.dart';
import '../../../shared/widgets/state_views.dart';
import '../../../shared/widgets/status_chip.dart';
import '../providers/profile_provider.dart';

// Hồ sơ cá nhân đầy đủ (giống trang "Hồ sơ của tôi" bên web): thông tin cá nhân + công việc.
// Chỉ tài khoản có employee.manage (admin) mới sửa được SĐT/địa chỉ; nhân viên thường liên hệ Admin.
class ProfileDetailScreen extends StatefulWidget {
  const ProfileDetailScreen({super.key});

  @override
  State<ProfileDetailScreen> createState() => _ProfileDetailScreenState();
}

class _ProfileDetailScreenState extends State<ProfileDetailScreen> {
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  bool _editing = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final provider = context.read<ProfileProvider>();
    if (provider.employee == null) provider.load();
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  void _startEdit(Employee e) {
    _phoneController.text = e.phone ?? '';
    _addressController.text = e.address ?? '';
    setState(() => _editing = true);
  }

  Future<void> _save() async {
    final provider = context.read<ProfileProvider>();
    setState(() => _saving = true);
    final ok = await provider.updateContact(
      phone: _phoneController.text.trim(),
      address: _addressController.text.trim(),
    );
    if (!mounted) return;
    setState(() {
      _saving = false;
      if (ok) _editing = false;
    });
    showMessage(context, ok ? 'Đã cập nhật hồ sơ.' : (provider.errorMessage ?? 'Không thể cập nhật hồ sơ.'), error: !ok);
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ProfileProvider>();
    final e = provider.employee;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text('Hồ sơ của tôi'),
        backgroundColor: const Color(0xFF2A5CAA),
        foregroundColor: Colors.white,
        actions: [
          if (e != null)
            PermissionGate(
              code: 'employee.manage',
              child: _editing
                  ? TextButton(
                      onPressed: _saving ? null : _save,
                      child: Text(_saving ? 'Đang lưu...' : 'Lưu', style: const TextStyle(color: Colors.white)),
                    )
                  : TextButton(
                      onPressed: () => _startEdit(e),
                      child: const Text('Chỉnh sửa', style: TextStyle(color: Colors.white)),
                    ),
            ),
        ],
      ),
      body: e == null
          ? (provider.errorMessage != null
              ? ErrorView(message: provider.errorMessage!, onRetry: provider.load)
              : const EmptyView(
                  message: 'Tài khoản này chưa được liên kết với một hồ sơ nhân viên.',
                  icon: Icons.person_off_outlined,
                ))
          : _buildContent(e),
    );
  }

  Widget _buildContent(Employee e) {
    final date = DateFormat('dd/MM/yyyy');
    final initials = e.fullName.trim().split(RegExp(r'\s+')).reversed.take(2).toList().reversed.map((p) => p.isEmpty ? '' : p[0]).join();
    final active = e.employmentStatus == 'Active';

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: const Color(0xFF2563EB),
                  child: Text(initials, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(e.fullName, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      Text('${e.employeeCode} · ${e.positionName}', style: const TextStyle(color: Colors.grey)),
                      if (e.employmentStatus != null) ...[
                        const SizedBox(height: 6),
                        StatusChip(label: e.employmentStatus!, color: active ? StatusChip.success : StatusChip.danger),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        _section('Thông tin cá nhân', [
          _row('Email', e.email),
          _editing ? _field('Điện thoại', _phoneController, TextInputType.phone) : _row('Điện thoại', e.phone),
          _row('Ngày sinh', e.dateOfBirth == null ? null : date.format(e.dateOfBirth!)),
          _row('Giới tính', _genderLabel(e.gender)),
          _editing ? _field('Địa chỉ', _addressController, TextInputType.streetAddress) : _row('Địa chỉ', e.address),
        ]),
        const SizedBox(height: 12),
        _section('Thông tin công việc', [
          _row('Phòng ban', e.departmentName),
          _row('Chức vụ', e.positionName),
          _row('Quản lý trực tiếp', e.managerName ?? e.managerCode),
          _row('Ngày vào làm', e.hireDate == null ? null : date.format(e.hireDate!)),
        ]),
        // Không có quyền sửa: giải thích như banner bên web.
        PermissionGate(
          code: 'employee.manage',
          fallback: const Padding(
            padding: EdgeInsets.only(top: 12),
            child: Card(
              child: ListTile(
                leading: Icon(Icons.info_outline, color: Color(0xFF2A5CAA)),
                title: Text('Cần thay đổi thông tin?'),
                subtitle: Text('Hiện chỉ Admin được chỉnh sửa hồ sơ nhân viên. Liên hệ Admin để cập nhật thông tin cá nhân.'),
              ),
            ),
          ),
          child: const SizedBox.shrink(),
        ),
      ],
    );
  }

  String? _genderLabel(String? gender) {
    switch (gender) {
      case 'Male':
        return 'Nam';
      case 'Female':
        return 'Nữ';
      default:
        return gender;
    }
  }

  Widget _section(String title, List<Widget> children) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF2A5CAA))),
            const Divider(height: 24),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _row(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 130, child: Text(label, style: const TextStyle(color: Colors.grey))),
          Expanded(
            child: Text((value == null || value.isEmpty) ? '--' : value, style: const TextStyle(fontWeight: FontWeight.w500)),
          ),
        ],
      ),
    );
  }

  Widget _field(String label, TextEditingController controller, TextInputType type) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        keyboardType: type,
        decoration: InputDecoration(labelText: label, border: const OutlineInputBorder(), isDense: true),
      ),
    );
  }
}
