import 'package:flutter/material.dart';

// Các trạng thái dùng chung cho màn hình danh sách: đang tải, rỗng, lỗi (có nút thử lại).
class LoadingView extends StatelessWidget {
  const LoadingView({super.key});

  @override
  Widget build(BuildContext context) => const Center(child: CircularProgressIndicator());
}

// Căn giữa nội dung; khi chiều cao bị giới hạn thì cho cuộn để không tràn (màn thấp, chữ lớn).
// Khi đặt trong ListView (chiều cao vô hạn) thì chỉ căn giữa, không lồng thêm vùng cuộn.
class _CenteredScroll extends StatelessWidget {
  final Widget child;

  const _CenteredScroll({required this.child});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const padding = EdgeInsets.all(24);
        if (!constraints.hasBoundedHeight) {
          return Center(
            child: Padding(padding: padding, child: child),
          );
        }
        return Center(
          child: SingleChildScrollView(padding: padding, child: child),
        );
      },
    );
  }
}

class EmptyView extends StatelessWidget {
  final String message;
  final IconData icon;

  const EmptyView({super.key, required this.message, this.icon = Icons.inbox_outlined});

  @override
  Widget build(BuildContext context) {
    return _CenteredScroll(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 56, color: Colors.grey.shade400),
          const SizedBox(height: 12),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }
}

class ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;

  const ErrorView({super.key, required this.message, this.onRetry});

  @override
  Widget build(BuildContext context) {
    return _CenteredScroll(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.error_outline, size: 56, color: Colors.red.shade300),
          const SizedBox(height: 12),
          Text(message, textAlign: TextAlign.center),
          if (onRetry != null) ...[
            const SizedBox(height: 12),
            OutlinedButton.icon(onPressed: onRetry, icon: const Icon(Icons.refresh), label: const Text('Thử lại')),
          ],
        ],
      ),
    );
  }
}
