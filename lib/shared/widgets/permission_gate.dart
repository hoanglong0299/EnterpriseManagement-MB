import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../features/auth/providers/auth_provider.dart';

// Chỉ hiện [child] khi tài khoản có permission [code] (ẩn nút/mục theo từng hành động).
// Backend vẫn kiểm tra quyền thật ở mỗi API, đây chỉ để giao diện không hiện nút không dùng được.
class PermissionGate extends StatelessWidget {
  final String code;
  final Widget child;
  final Widget? fallback;

  const PermissionGate({super.key, required this.code, required this.child, this.fallback});

  @override
  Widget build(BuildContext context) {
    final allowed = context.watch<AuthProvider>().can(code);
    return allowed ? child : (fallback ?? const SizedBox.shrink());
  }
}
