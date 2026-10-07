import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../models/leave_type_admin.dart';
import '../../../shared/widgets/confirm_dialog.dart';
import '../providers/admin_leave_types_provider.dart';

const Color _primary = Color(0xFF2A5CAA);

// Mở form tạo/sửa dạng bottom sheet. Sheet nằm ngoài cây màn hình nên truyền lại provider vào.
Future<void> showLeaveTypeForm(BuildContext context, {LeaveTypeAdmin? editing}) {
  final provider = context.read<AdminLeaveTypesProvider>();
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (ctx) => ChangeNotifierProvider.value(
      value: provider,
      child: Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: LeaveTypeFormSheet(editing: editing),
      ),
    ),
  );
}

// Form tạo/sửa loại nghỉ phép: mã chỉ nhập khi tạo, khi sửa mã bị khoá.
class LeaveTypeFormSheet extends StatefulWidget {
  final LeaveTypeAdmin? editing;

  const LeaveTypeFormSheet({super.key, this.editing});

  @override
  State<LeaveTypeFormSheet> createState() => _LeaveTypeFormSheetState();
}

class _LeaveTypeFormSheetState extends State<LeaveTypeFormSheet> {
  late final TextEditingController _code;
  late final TextEditingController _name;
  late final TextEditingController _amount;
  late final TextEditingController _desc;
  late String _unit;
  late String _period;
  late bool _isPaid;
  bool _saving = false;
  String? _error;

  bool get _isEdit => widget.editing != null;

  @override
  void initState() {
    super.initState();
    final t = widget.editing;
    _code = TextEditingController(text: t?.leaveTypeCode ?? '');
    _name = TextEditingController(text: t?.leaveTypeName ?? '');
    _amount = TextEditingController(text: t == null ? '1' : LeaveTypeAdmin.formatAmount(t.accrualAmount));
    _desc = TextEditingController(text: t?.description ?? '');
    _unit = t?.accrualUnit ?? 'Days';
    _period = t?.accrualPeriod ?? 'ProratedYearly';
    _isPaid = t?.isPaid ?? true;
  }

  @override
  void dispose() {
    _code.dispose();
    _name.dispose();
    _amount.dispose();
    _desc.dispose();
    super.dispose();
  }

  // Kiểm tra phía client, trả về thông báo lỗi hoặc null nếu hợp lệ.
  String? _validate(double? amount) {
    if (!_isEdit) {
      final code = _code.text.trim();
      if (code.isEmpty) return 'Vui lòng nhập mã loại nghỉ.';
      if (!RegExp(r'^[A-Z][A-Z0-9_]*$').hasMatch(code)) return 'Mã chỉ gồm chữ HOA, số, gạch dưới và bắt đầu bằng chữ cái.';
    }
    if (_name.text.trim().isEmpty) return 'Vui lòng nhập tên loại nghỉ.';
    if (amount == null || amount <= 0) return 'Số lượng cấp phải là số lớn hơn 0.';
    return null;
  }

  Future<void> _save() async {
    final amount = double.tryParse(_amount.text.trim().replaceAll(',', '.'));
    final invalid = _validate(amount);
    if (invalid != null) {
      setState(() => _error = invalid);
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    final desc = _desc.text.trim();
    final err = await context.read<AdminLeaveTypesProvider>().save(
          editing: widget.editing,
          code: _code.text.trim(),
          name: _name.text.trim(),
          amount: amount!,
          unit: _unit,
          period: _period,
          isPaid: _isPaid,
          description: desc.isEmpty ? null : desc,
        );
    if (!mounted) return;
    if (err == null) {
      showMessage(context, _isEdit ? 'Đã cập nhật loại nghỉ.' : 'Đã tạo loại nghỉ.');
      Navigator.pop(context);
    } else {
      // Giữ form mở và hiện nguyên văn lỗi backend (vd đổi đơn vị khi đã có số dư).
      setState(() {
        _saving = false;
        _error = err;
      });
    }
  }

  InputDecoration _input(String label, {String? hint}) =>
      InputDecoration(labelText: label, hintText: hint, border: const OutlineInputBorder(), isDense: true);

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(_isEdit ? 'Sửa loại nghỉ' : 'Thêm loại nghỉ', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ),
        ),
        Flexible(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextField(
                  controller: _code,
                  enabled: !_isEdit,
                  textCapitalization: TextCapitalization.characters,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9_]')),
                    TextInputFormatter.withFunction((o, n) => n.copyWith(text: n.text.toUpperCase())),
                  ],
                  decoration: _input('Mã loại nghỉ *', hint: 'VD: SICK_LEAVE').copyWith(helperText: _isEdit ? 'Mã không đổi được sau khi tạo.' : null),
                ),
                const SizedBox(height: 12),
                TextField(controller: _name, decoration: _input('Tên loại nghỉ *')),
                const SizedBox(height: 12),
                Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Expanded(
                    child: TextField(
                      controller: _amount,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: _input('Số lượng cấp *'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: _unit,
                      decoration: _input('Đơn vị'),
                      items: LeaveTypeAdmin.unitLabels.entries.map((e) => DropdownMenuItem(value: e.key, child: Text(e.value))).toList(),
                      onChanged: (v) => setState(() => _unit = v ?? _unit),
                    ),
                  ),
                ]),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: _period,
                  isExpanded: true,
                  decoration: _input('Chu kỳ cấp'),
                  items: LeaveTypeAdmin.periodLabels.entries
                      .map((e) => DropdownMenuItem(value: e.key, child: Text(e.value, overflow: TextOverflow.ellipsis)))
                      .toList(),
                  onChanged: (v) => setState(() => _period = v ?? _period),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 6, left: 4),
                  child: Text(LeaveTypeAdmin.periodHints[_period] ?? '', style: TextStyle(fontSize: 12, color: Colors.grey.shade700)),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Nghỉ có lương'),
                  value: _isPaid,
                  onChanged: (v) => setState(() => _isPaid = v),
                ),
                TextField(controller: _desc, maxLines: 2, decoration: _input('Mô tả')),
                if (_isEdit)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Text(
                      'Lưu ý: sửa quy tắc cấp chỉ áp dụng cho số dư tạo MỚI, không thay đổi số dư đã cấp cho nhân viên. '
                      'Chỉ đổi được đơn vị khi loại nghỉ chưa có đơn hoặc số dư.',
                      style: TextStyle(fontSize: 12, color: Colors.orange.shade800),
                    ),
                  ),
                if (_error != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Text(_error!, style: const TextStyle(fontSize: 13, color: Colors.red)),
                  ),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(children: [
            Expanded(child: OutlinedButton(onPressed: _saving ? null : () => Navigator.pop(context), child: const Text('Huỷ'))),
            const SizedBox(width: 12),
            Expanded(
              child: FilledButton(
                onPressed: _saving ? null : _save,
                style: FilledButton.styleFrom(backgroundColor: _primary),
                child: _saving
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('Lưu'),
              ),
            ),
          ]),
        ),
      ],
    );
  }
}
