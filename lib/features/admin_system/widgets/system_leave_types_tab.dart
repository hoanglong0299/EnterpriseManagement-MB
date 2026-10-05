import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../models/system_leave_type.dart';
import '../../../shared/widgets/confirm_dialog.dart';
import '../../../shared/widgets/permission_gate.dart';
import '../../../shared/widgets/status_chip.dart';
import '../providers/system_provider.dart';
import 'system_common.dart';

// Tab Loại nghỉ phép (leavetype.manage): danh sách + quy tắc tích luỹ, tạo mới.
// Backend hiện chỉ có GET danh sách và POST tạo, chưa có API sửa/khoá nên app chưa có nút sửa.
class SystemLeaveTypesTab extends StatelessWidget {
  const SystemLeaveTypesTab({super.key});

  static String _amount(double v) => v == v.roundToDouble() ? v.toInt().toString() : v.toString();

  @override
  Widget build(BuildContext context) {
    final p = context.watch<SystemProvider>();
    return SystemSectionList<SystemLeaveType>(
      state: p.leaveTypes,
      onReload: p.loadLeaveTypes,
      emptyMessage: 'Chưa có loại nghỉ phép.',
      header: PermissionGate(
        code: 'leavetype.manage',
        child: Align(
          alignment: Alignment.centerRight,
          child: FilledButton.icon(
            onPressed: () => showFormSheet(context, (_) => const _LeaveTypeForm()),
            icon: const Icon(Icons.add),
            label: const Text('Tạo loại nghỉ'),
            style: FilledButton.styleFrom(backgroundColor: systemPrimary),
          ),
        ),
      ),
      itemBuilder: (t) => SystemCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Expanded(child: Text(t.leaveTypeName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15))),
              StatusChip(label: t.isPaid ? 'Có lương' : 'Không lương', color: t.isPaid ? StatusChip.success : StatusChip.warning),
            ]),
            const SizedBox(height: 4),
            Text('Mã: ${t.leaveTypeCode}', style: const TextStyle(fontSize: 13)),
            Text(
              'Tích luỹ: ${_amount(t.accrualAmount)} ${SystemLeaveType.unitLabels[t.accrualUnit] ?? t.accrualUnit}',
              style: const TextStyle(fontSize: 13),
            ),
            Text(SystemLeaveType.periodLabels[t.accrualPeriod] ?? t.accrualPeriod, style: TextStyle(fontSize: 13, color: Colors.grey.shade700)),
            if ((t.description ?? '').isNotEmpty) Text(t.description!, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
            if (!t.isActive) const Padding(padding: EdgeInsets.only(top: 6), child: StatusChip(label: 'Đã tắt', color: StatusChip.danger)),
          ],
        ),
      ),
    );
  }
}

class _LeaveTypeForm extends StatefulWidget {
  const _LeaveTypeForm();

  @override
  State<_LeaveTypeForm> createState() => _LeaveTypeFormState();
}

class _LeaveTypeFormState extends State<_LeaveTypeForm> {
  final _code = TextEditingController();
  final _name = TextEditingController();
  final _amount = TextEditingController(text: '1');
  final _desc = TextEditingController();
  String _unit = 'Days';
  String _period = 'ProratedYearly';
  bool _isPaid = true;
  bool _saving = false;

  @override
  void dispose() {
    _code.dispose();
    _name.dispose();
    _amount.dispose();
    _desc.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final amount = double.tryParse(_amount.text.trim().replaceAll(',', '.'));
    if (_code.text.trim().isEmpty || _name.text.trim().isEmpty) {
      showMessage(context, 'Vui lòng nhập mã và tên loại nghỉ.', error: true);
      return;
    }
    if (amount == null || amount <= 0) {
      showMessage(context, 'Số lượng tích luỹ phải là số lớn hơn 0.', error: true);
      return;
    }
    setState(() => _saving = true);
    final ok = await runWrite(
      context,
      () => context.read<SystemProvider>().createLeaveType(
            code: _code.text.trim(),
            name: _name.text.trim(),
            amount: amount,
            unit: _unit,
            period: _period,
            isPaid: _isPaid,
            description: _desc.text.trim().isEmpty ? null : _desc.text.trim(),
          ),
      'Đã tạo loại nghỉ phép.',
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
      title: 'Tạo loại nghỉ phép',
      saving: _saving,
      onSave: _save,
      children: [
        TextField(controller: _code, decoration: systemInput('Mã loại nghỉ *')),
        const SizedBox(height: 12),
        TextField(controller: _name, decoration: systemInput('Tên loại nghỉ *')),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(
            child: TextField(controller: _amount, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: systemInput('Số lượng tích luỹ *')),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: DropdownButtonFormField<String>(
              initialValue: _unit,
              decoration: systemInput('Đơn vị'),
              items: SystemLeaveType.unitLabels.entries.map((e) => DropdownMenuItem(value: e.key, child: Text(e.value))).toList(),
              onChanged: (v) => setState(() => _unit = v ?? _unit),
            ),
          ),
        ]),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          initialValue: _period,
          isExpanded: true,
          decoration: systemInput('Quy tắc tích luỹ'),
          items: SystemLeaveType.periodLabels.entries
              .map((e) => DropdownMenuItem(value: e.key, child: Text(e.value, overflow: TextOverflow.ellipsis)))
              .toList(),
          onChanged: (v) => setState(() => _period = v ?? _period),
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Nghỉ có lương'),
          value: _isPaid,
          onChanged: (v) => setState(() => _isPaid = v),
        ),
        TextField(controller: _desc, maxLines: 2, decoration: systemInput('Mô tả')),
      ],
    );
  }
}
