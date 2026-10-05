import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/network/api_client.dart';
import '../../../services/account_service.dart';
import '../../../shared/widgets/confirm_dialog.dart';
import '../../auth/providers/auth_provider.dart';

// Cài đặt tài khoản (giống trang "Cài đặt tài khoản" bên web): thông tin đăng nhập + đổi mật khẩu.
class AccountSettingsScreen extends StatefulWidget {
  const AccountSettingsScreen({super.key});

  @override
  State<AccountSettingsScreen> createState() => _AccountSettingsScreenState();
}

class _AccountSettingsScreenState extends State<AccountSettingsScreen> {
  final _currentController = TextEditingController();
  final _newController = TextEditingController();
  final _confirmController = TextEditingController();

  bool _showCurrent = false;
  bool _showNew = false;
  bool _showConfirm = false;
  bool _sending = false;

  @override
  void dispose() {
    _currentController.dispose();
    _newController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final current = _currentController.text;
    final next = _newController.text;
    final confirm = _confirmController.text;

    if (current.isEmpty || next.isEmpty || confirm.isEmpty) {
      return showMessage(context, 'Vui lòng nhập đủ các trường.', error: true);
    }
    if (next.length < 8) {
      return showMessage(context, 'Mật khẩu mới phải có ít nhất 8 ký tự.', error: true);
    }
    if (next != confirm) {
      return showMessage(context, 'Mật khẩu mới nhập lại không khớp.', error: true);
    }

    setState(() => _sending = true);
    try {
      await AccountService(context.read<ApiClient>()).changePassword(currentPassword: current, newPassword: next);
      if (!mounted) return;
      _currentController.clear();
      _newController.clear();
      _confirmController.clear();
      showMessage(context, 'Đã đổi mật khẩu.');
    } catch (e) {
      if (!mounted) return;
      showMessage(context, e.toString().replaceFirst('Exception: ', ''), error: true);
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = context.watch<AuthProvider>().session;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text('Cài đặt tài khoản'),
        backgroundColor: const Color(0xFF2A5CAA),
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _section(
            'Thông tin tài khoản',
            Column(
              children: [
                _infoRow('Tên đăng nhập', Text(session?.username ?? '--')),
                _infoRow('Mã nhân viên', Text(session?.employeeCode ?? '--')),
                _infoRow(
                  'Vai trò',
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: [
                      for (final role in session?.roles ?? const <String>[])
                        Chip(
                          label: Text(role, style: const TextStyle(fontSize: 12)),
                          visualDensity: VisualDensity.compact,
                          padding: EdgeInsets.zero,
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _section(
            'Đổi mật khẩu',
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _passwordField('Mật khẩu hiện tại', _currentController, _showCurrent, () => setState(() => _showCurrent = !_showCurrent)),
                const SizedBox(height: 14),
                _passwordField('Mật khẩu mới (ít nhất 8 ký tự)', _newController, _showNew, () => setState(() => _showNew = !_showNew)),
                const SizedBox(height: 14),
                _passwordField('Nhập lại mật khẩu mới', _confirmController, _showConfirm, () => setState(() => _showConfirm = !_showConfirm)),
                const SizedBox(height: 20),
                SizedBox(
                  height: 48,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2A5CAA), foregroundColor: Colors.white),
                    onPressed: _sending ? null : _submit,
                    child: _sending
                        ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Text('ĐỔI MẬT KHẨU', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _section(String title, Widget child) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF2A5CAA))),
            const Divider(height: 24),
            child,
          ],
        ),
      ),
    );
  }

  Widget _infoRow(String label, Widget value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 110, child: Text(label, style: const TextStyle(color: Colors.grey))),
          Expanded(child: DefaultTextStyle.merge(style: const TextStyle(fontWeight: FontWeight.w500), child: value)),
        ],
      ),
    );
  }

  Widget _passwordField(String label, TextEditingController controller, bool visible, VoidCallback toggle) {
    return TextField(
      controller: controller,
      obscureText: !visible,
      autocorrect: false,
      enableSuggestions: false,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        suffixIcon: IconButton(
          icon: Icon(visible ? Icons.visibility_off : Icons.visibility),
          onPressed: toggle,
        ),
      ),
    );
  }
}
