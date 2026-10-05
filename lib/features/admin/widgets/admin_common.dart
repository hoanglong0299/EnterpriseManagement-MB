import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../models/admin_user.dart';
import '../../../shared/widgets/confirm_dialog.dart';
import '../../../shared/widgets/status_chip.dart';

const Color adminPrimary = Color(0xFF2A5CAA);
const Color adminBackground = Color(0xFFF5F7FA);

String errText(Object e) => e.toString().replaceFirst('Exception: ', '');

// Chạy một thao tác ghi, báo kết quả bằng SnackBar. Trả về true nếu thành công.
Future<bool> runAdminAction(BuildContext context, Future<void> Function() action, String successMessage) async {
  try {
    await action();
    if (context.mounted) showMessage(context, successMessage);
    return true;
  } catch (e) {
    if (context.mounted) showMessage(context, errText(e), error: true);
    return false;
  }
}

Widget activeChip(bool active, {String on = 'Hoạt động', String off = 'Ngừng'}) =>
    StatusChip(label: active ? on : off, color: active ? StatusChip.success : StatusChip.neutral);

// Ô tìm kiếm dùng chung cho các danh sách.
class AdminSearchField extends StatelessWidget {
  final String hint;
  final ValueChanged<String> onChanged;

  const AdminSearchField({super.key, required this.hint, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return TextField(
      onChanged: onChanged,
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: const Icon(Icons.search),
        filled: true,
        fillColor: Colors.white,
        isDense: true,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
      ),
    );
  }
}

// Dòng "nhãn: giá trị" trong card / chi tiết.
class InfoLine extends StatelessWidget {
  final String label;
  final String value;

  const InfoLine(this.label, this.value, {super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 110, child: Text(label, style: TextStyle(color: Colors.grey.shade600, fontSize: 13))),
          Expanded(child: Text(value.isEmpty ? '--' : value, style: const TextStyle(fontSize: 13))),
        ],
      ),
    );
  }
}

// Bottom sheet hiển thị mật khẩu tạm (chỉ hiện một lần), có nút ẩn/hiện và sao chép.
Future<void> showCredentialSheet(BuildContext context, AdminCredential credential) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (_) => _CredentialSheet(credential: credential),
  );
}

class _CredentialSheet extends StatefulWidget {
  final AdminCredential credential;

  const _CredentialSheet({required this.credential});

  @override
  State<_CredentialSheet> createState() => _CredentialSheetState();
}

class _CredentialSheetState extends State<_CredentialSheet> {
  bool _show = false;

  @override
  Widget build(BuildContext context) {
    final c = widget.credential;
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 20, 20, 20 + MediaQuery.of(context).viewInsets.bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(c.isReset ? 'Đã đặt lại mật khẩu' : 'Thông tin đăng nhập vừa tạo',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text('Gửi thông tin dưới đây cho nhân viên. Mật khẩu chỉ hiển thị một lần.'),
          const SizedBox(height: 12),
          InfoLine('Tên đăng nhập', c.username),
          Row(
            children: [
              SizedBox(width: 110, child: Text('Mật khẩu tạm', style: TextStyle(color: Colors.grey.shade600, fontSize: 13))),
              Expanded(
                child: Text(
                  _show ? c.password : '•' * c.password.length,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontFamily: 'monospace'),
                ),
              ),
              IconButton(
                icon: Icon(_show ? Icons.visibility_off : Icons.visibility),
                onPressed: () => setState(() => _show = !_show),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.copy),
                  label: const Text('Sao chép'),
                  onPressed: () async {
                    await Clipboard.setData(ClipboardData(text: 'Tên đăng nhập: ${c.username}\nMật khẩu: ${c.password}'));
                    if (context.mounted) showMessage(context, 'Đã sao chép thông tin đăng nhập.');
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(child: FilledButton(onPressed: () => Navigator.pop(context), child: const Text('Đóng'))),
            ],
          ),
        ],
      ),
    );
  }
}

// Khung bottom sheet cho form: tiêu đề + nội dung cuộn + chừa chỗ cho bàn phím.
class FormSheet extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const FormSheet({super.key, required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }
}

InputDecoration fieldDecoration(String label, {String? hint}) => InputDecoration(
      labelText: label,
      hintText: hint,
      border: const OutlineInputBorder(),
      isDense: true,
    );
