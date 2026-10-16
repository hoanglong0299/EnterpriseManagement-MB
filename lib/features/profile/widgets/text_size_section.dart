import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../app/theme.dart';
import '../../../core/settings/text_size_provider.dart';

// Mục "Cỡ chữ" trong Cài đặt: chọn một trong các mức, áp dụng ngay cho toàn app, kèm đoạn xem trước.
class TextSizeSection extends StatelessWidget {
  const TextSizeSection({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TextSizeProvider>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Chọn cỡ chữ hiển thị trong app. "Mặc định" là cỡ chữ hiện tại của app.',
          style: TextStyle(color: Colors.black54, fontSize: 13),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final option in TextSizeOption.values)
              ChoiceChip(
                label: Text(option.label),
                selected: provider.option == option,
                selectedColor: AppColors.tint,
                onSelected: (_) => provider.select(option),
              ),
          ],
        ),
        const SizedBox(height: 14),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Text(
            'Xem trước: Chấm công vào lúc 08:00, đơn nghỉ phép đã được duyệt.',
            style: TextStyle(fontSize: 14, color: AppColors.ink),
          ),
        ),
      ],
    );
  }
}
