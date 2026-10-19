import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/network/api_client.dart';
import '../../../core/utils/helpers.dart';
import '../../../models/privacy.dart';
import '../../../services/privacy_service.dart';
import '../../../shared/widgets/state_views.dart';

// Chính sách dữ liệu chấm công (vị trí GPS, ảnh) lấy từ backend (cùng nội dung với web) kèm trạng thái đồng ý của bạn.
class PrivacyStatementScreen extends StatefulWidget {
  const PrivacyStatementScreen({super.key});

  @override
  State<PrivacyStatementScreen> createState() => _PrivacyStatementScreenState();
}

class _PrivacyStatementScreenState extends State<PrivacyStatementScreen> {
  PrivacyPolicy? _policy;
  PrivacyConsent? _consent;
  String? _error;
  bool _busy = false;
  late final PrivacyService _service = PrivacyService(context.read<ApiClient>());

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _error = null);
    try {
      final results = await Future.wait([_service.getPolicy(), _service.getConsent()]);
      if (!mounted) return;
      setState(() {
        _policy = results[0] as PrivacyPolicy;
        _consent = results[1] as PrivacyConsent;
      });
    } catch (e) {
      if (mounted) setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    }
  }

  Future<void> _change(Future<PrivacyConsent> Function() action, String message) async {
    setState(() => _busy = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      final result = await action();
      if (!mounted) return;
      setState(() => _consent = result);
      messenger.showSnackBar(SnackBar(content: Text(message), backgroundColor: Colors.green));
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.toString().replaceFirst('Exception: ', '')), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final policy = _policy;
    final consent = _consent;

    Widget body;
    if (_error != null && policy == null) {
      body = ErrorView(message: _error!, onRetry: _load);
    } else if (policy == null || consent == null) {
      body = const LoadingView();
    } else {
      body = ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Card(
            elevation: 0,
            color: const Color(0xFFF6F4FC),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Sự đồng ý của bạn', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  Text(consent.accepted
                      ? 'Bạn đã đồng ý chính sách này${consent.acceptedAt == null ? '' : ' lúc ${formatDateTime(consent.acceptedAt!.toLocal())}'}.'
                      : 'Bạn chưa đồng ý chính sách này nên chưa chấm công được bằng ứng dụng.'),
                  const SizedBox(height: 10),
                  consent.accepted
                      ? OutlinedButton(
                          onPressed: _busy ? null : () => _change(_service.withdraw, 'Đã rút lại đồng ý.'),
                          child: const Text('Rút lại đồng ý'),
                        )
                      : ElevatedButton(
                          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF5A3FD8), foregroundColor: Colors.white),
                          onPressed: _busy ? null : () => _change(_service.accept, 'Đã ghi nhận đồng ý của bạn.'),
                          child: const Text('Tôi đồng ý'),
                        ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          for (final s in policy.sections)
            Padding(
              padding: const EdgeInsets.only(bottom: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(s.heading, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF5A3FD8))),
                  const SizedBox(height: 8),
                  Text(s.body, style: const TextStyle(fontSize: 14, color: Colors.black87, height: 1.5)),
                ],
              ),
            ),
        ],
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Chính sách quyền riêng tư'),
        backgroundColor: const Color(0xFF5A3FD8),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: body,
    );
  }
}
