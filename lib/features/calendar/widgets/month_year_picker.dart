import 'package:flutter/material.dart';

import '../../../app/theme.dart';

const int _minYear = 2000;
const int _maxYear = 2100;
const int _yearsPerPage = 12;

// Mở bảng chọn tháng/năm giống lịch của điện thoại: lưới 12 tháng, bấm số năm để chọn năm rồi quay lại chọn tháng.
// Trả về ngày mùng 1 của tháng được chọn, hoặc null nếu đóng mà không chọn.
Future<DateTime?> showMonthYearPicker(BuildContext context, DateTime initial) {
  return showModalBottomSheet<DateTime>(
    context: context,
    backgroundColor: Colors.white,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
    builder: (_) => _MonthYearPicker(initial: initial),
  );
}

class _MonthYearPicker extends StatefulWidget {
  final DateTime initial;

  const _MonthYearPicker({required this.initial});

  @override
  State<_MonthYearPicker> createState() => _MonthYearPickerState();
}

class _MonthYearPickerState extends State<_MonthYearPicker> {
  late int _year = widget.initial.year;
  bool _pickingYear = false;
  // Trang năm đang xem (mỗi trang 12 năm), bắt đầu từ năm đang chọn.
  late int _pageStart = _pageStartOf(widget.initial.year);

  static int _pageStartOf(int year) => _minYear + ((year - _minYear) ~/ _yearsPerPage) * _yearsPerPage;

  void _shiftPage(int pages) {
    final next = _pageStart + pages * _yearsPerPage;
    if (next < _minYear || next > _maxYear) return;
    setState(() => _pageStart = next);
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(color: Colors.black12, borderRadius: BorderRadius.circular(2)),
            ),
            const SizedBox(height: 12),
            _pickingYear ? _yearHeader() : _monthHeader(),
            const SizedBox(height: 12),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 180),
              child: _pickingYear ? _yearGrid() : _monthGrid(),
            ),
          ],
        ),
      ),
    );
  }

  // Đầu lưới tháng: < năm > ; bấm vào số năm để chuyển sang chọn năm.
  Widget _monthHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        IconButton(
          icon: const Icon(Icons.chevron_left, color: AppColors.primary),
          onPressed: _year > _minYear ? () => setState(() => _year--) : null,
        ),
        InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: () => setState(() {
            _pageStart = _pageStartOf(_year);
            _pickingYear = true;
          }),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('$_year', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.ink)),
                const Icon(Icons.arrow_drop_down, color: AppColors.primary),
              ],
            ),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.chevron_right, color: AppColors.primary),
          onPressed: _year < _maxYear ? () => setState(() => _year++) : null,
        ),
      ],
    );
  }

  Widget _yearHeader() {
    final end = (_pageStart + _yearsPerPage - 1).clamp(_minYear, _maxYear);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        IconButton(
          icon: const Icon(Icons.chevron_left, color: AppColors.primary),
          onPressed: _pageStart > _minYear ? () => _shiftPage(-1) : null,
        ),
        Text('$_pageStart - $end', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.ink)),
        IconButton(
          icon: const Icon(Icons.chevron_right, color: AppColors.primary),
          onPressed: _pageStart + _yearsPerPage <= _maxYear ? () => _shiftPage(1) : null,
        ),
      ],
    );
  }

  Widget _monthGrid() {
    final now = DateTime.now();
    return GridView.count(
      key: const ValueKey('months'),
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 3,
      childAspectRatio: 2,
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      children: [
        for (var m = 1; m <= 12; m++)
          _cell(
            label: 'Tháng $m',
            selected: _year == widget.initial.year && m == widget.initial.month,
            current: _year == now.year && m == now.month,
            onTap: () => Navigator.pop(context, DateTime(_year, m, 1)),
          ),
      ],
    );
  }

  Widget _yearGrid() {
    final now = DateTime.now();
    return GridView.count(
      key: const ValueKey('years'),
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 3,
      childAspectRatio: 2,
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      children: [
        for (var y = _pageStart; y < _pageStart + _yearsPerPage && y <= _maxYear; y++)
          _cell(
            label: '$y',
            selected: y == _year,
            current: y == now.year,
            onTap: () => setState(() {
              _year = y;
              _pickingYear = false;
            }),
          ),
      ],
    );
  }

  Widget _cell({required String label, required bool selected, required bool current, required VoidCallback onTap}) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Container(
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : AppColors.tint.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(14),
          border: current && !selected ? Border.all(color: AppColors.primary, width: 1.4) : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 15,
            fontWeight: selected || current ? FontWeight.w700 : FontWeight.w500,
            color: selected ? Colors.white : AppColors.ink,
          ),
        ),
      ),
    );
  }
}
