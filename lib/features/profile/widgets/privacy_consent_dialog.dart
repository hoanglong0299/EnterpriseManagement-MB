import 'package:flutter/material.dart';

import '../../../models/privacy.dart';
import '../../../services/privacy_service.dart';

// Bảo đảm người dùng đã đồng ý chính sách thu thập vị trí/ảnh trước khi chấm công.
// Trả về true nếu đã (hoặc vừa) đồng ý; false nếu từ chối hoặc không kiểm tra được (kèm [onError]).
Future<bool> ensurePrivacyConsent(
  BuildContext context,
  PrivacyService service, {
  required void Function(String message) onError,
}) async {
  try {
    final consent = await service.getConsent();
    if (consent.accepted) return true;
    if (!context.mounted) return false;

    final policy = await service.getPolicy();
    if (!context.mounted) return false;
    final agreed = await showDialog<bool>(
      context: context,
      builder: (_) => PrivacyConsentDialog(policy: policy),
    );
    if (agreed != true) return false;
    await service.accept();
    return true;
  } catch (e) {
    onError(e.toString().replaceFirst('Exception: ', ''));
    return false;
  }
}

class PrivacyConsentDialog extends StatelessWidget {
  final PrivacyPolicy policy;
  const PrivacyConsentDialog({super.key, required this.policy});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Đồng ý thu thập vị trí và ảnh chấm công'),
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final s in policy.sections) ...[
                Text(s.heading, style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF5A3FD8))),
                const SizedBox(height: 4),
                Text(s.body, style: const TextStyle(height: 1.4)),
                const SizedBox(height: 12),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Không đồng ý')),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF5A3FD8), foregroundColor: Colors.white),
          onPressed: () => Navigator.pop(context, true),
          child: const Text('Tôi đồng ý'),
        ),
      ],
    );
  }
}
