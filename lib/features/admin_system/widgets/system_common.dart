import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../shared/widgets/confirm_dialog.dart';
import '../../../shared/widgets/state_views.dart';
import '../providers/system_provider.dart';

const Color systemPrimary = Color(0xFF2A5CAA);

// Khung chung của 1 tab: trạng thái tải/lỗi/rỗng, kéo để tải lại, nút tạo mới (đã gác quyền) ở đầu danh sách.
class SystemSectionList<T> extends StatelessWidget {
  final SectionState<T> state;
  final Future<void> Function() onReload;
  final String emptyMessage;
  final Widget? header;
  final Widget Function(T item) itemBuilder;

  const SystemSectionList({
    super.key,
    required this.state,
    required this.onReload,
    required this.emptyMessage,
    required this.itemBuilder,
    this.header,
  });

  @override
  Widget build(BuildContext context) {
    if (state.loading && !state.loaded) return const LoadingView();
    if (state.error != null && !state.loaded) return ErrorView(message: state.error!, onRetry: onReload);
    return RefreshIndicator(
      onRefresh: onReload,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(12),
        children: [
          if (header != null) Padding(padding: const EdgeInsets.only(bottom: 8), child: header),
          if (state.items.isEmpty)
            Padding(padding: const EdgeInsets.only(top: 48), child: EmptyView(message: emptyMessage))
          else
            ...state.items.map(itemBuilder),
        ],
      ),
    );
  }
}

// Thẻ 1 mục trong danh sách.
class SystemCard extends StatelessWidget {
  final Widget child;

  const SystemCard({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10), side: BorderSide(color: Colors.grey.shade200)),
      child: Padding(padding: const EdgeInsets.all(12), child: child),
    );
  }
}

// Mở form dạng bottom sheet cao gần hết màn hình, tự đẩy lên khi bật bàn phím.
// Sheet nằm ngoài cây của màn hình nên phải truyền lại SystemProvider vào.
Future<void> showFormSheet(BuildContext context, Widget Function(BuildContext) builder) {
  final provider = context.read<SystemProvider>();
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (ctx) => ChangeNotifierProvider.value(
      value: provider,
      child: Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: builder(ctx),
      ),
    ),
  );
}

// Chạy 1 thao tác ghi: hiện thông báo thành công/lỗi, trả về true nếu thành công.
Future<bool> runWrite(BuildContext context, Future<String?> Function() call, String successMessage) async {
  final error = await call();
  if (!context.mounted) return error == null;
  showMessage(context, error ?? successMessage, error: error != null);
  return error == null;
}

InputDecoration systemInput(String label, {String? hint}) =>
    InputDecoration(labelText: label, hintText: hint, border: const OutlineInputBorder(), isDense: true);

// Khung form: tiêu đề + nội dung cuộn được + nút Huỷ/Lưu.
class SystemFormFrame extends StatelessWidget {
  final String title;
  final List<Widget> children;
  final bool saving;
  final VoidCallback onSave;

  const SystemFormFrame({super.key, required this.title, required this.children, required this.saving, required this.onSave});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
          child: Align(alignment: Alignment.centerLeft, child: Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
        ),
        Flexible(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: children),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(children: [
            Expanded(child: OutlinedButton(onPressed: saving ? null : () => Navigator.pop(context), child: const Text('Huỷ'))),
            const SizedBox(width: 12),
            Expanded(
              child: FilledButton(
                onPressed: saving ? null : onSave,
                style: FilledButton.styleFrom(backgroundColor: systemPrimary),
                child: saving
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
