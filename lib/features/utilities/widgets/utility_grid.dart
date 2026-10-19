import 'package:flutter/material.dart';

import '../../../app/theme.dart';

// Một ô chức năng trên màn Tiện ích.
class UtilityItem {
  final String title;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  // Số việc đang chờ xử lý của chức năng; > 0 thì hiện chấm đỏ có số ở góc icon.
  final int badge;

  const UtilityItem({required this.title, required this.icon, required this.color, required this.onTap, this.badge = 0});
}

// Lưới ô chức năng co giãn theo màn hình: số cột tự đổi theo độ rộng và cỡ chữ,
// mỗi hàng tự cao theo ô nhiều chữ nhất nên tên dài xuống 2-3 dòng cũng không bị tràn.
class UtilityGrid extends StatelessWidget {
  final List<UtilityItem> items;

  const UtilityGrid({super.key, required this.items});

  static const double _spacing = 12;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final largeText = MediaQuery.textScalerOf(context).scale(10) > 13;
        final columns = (constraints.maxWidth < 300 || largeText) ? 2 : 3;

        final rows = <Widget>[];
        for (var start = 0; start < items.length; start += columns) {
          final chunk = items.skip(start).take(columns).toList();
          rows.add(
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (var i = 0; i < columns; i++) ...[
                    if (i > 0) const SizedBox(width: _spacing),
                    Expanded(child: i < chunk.length ? _UtilityTile(item: chunk[i]) : const SizedBox.shrink()),
                  ],
                ],
              ),
            ),
          );
          if (start + columns < items.length) rows.add(const SizedBox(height: _spacing));
        }
        return Column(children: rows);
      },
    );
  }
}

class _UtilityTile extends StatelessWidget {
  final UtilityItem item;

  const _UtilityTile({required this.item});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: item.onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.black.withValues(alpha: 0.06)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: item.color.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(item.icon, color: item.color, size: 24),
                  ),
                  if (item.badge > 0)
                    Positioned(
                      top: -6,
                      right: -8,
                      child: Container(
                        constraints: const BoxConstraints(minWidth: 20, minHeight: 20),
                        padding: const EdgeInsets.symmetric(horizontal: 5),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.white, width: 1.5),
                        ),
                        child: Text(
                          item.badge > 99 ? '99+' : '${item.badge}',
                          style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700, height: 1.1),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                item.title,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.ink, height: 1.2),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
