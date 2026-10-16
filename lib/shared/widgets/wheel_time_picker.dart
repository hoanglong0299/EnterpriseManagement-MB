import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../app/theme.dart';

// Chọn giờ bằng hai bánh xe cuộn lên/xuống (giờ, phút) giống màn hình đặt báo thức, thay cho đồng hồ kim.
// Trả về giờ đã chọn khi bấm "Xong", hoặc null nếu huỷ.
Future<TimeOfDay?> showWheelTimePicker(
  BuildContext context, {
  required TimeOfDay initial,
  String title = 'Chọn giờ',
}) {
  var selected = initial;

  return showModalBottomSheet<TimeOfDay>(
    context: context,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
    builder: (sheetContext) {
      return SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
              child: Row(
                children: [
                  TextButton(onPressed: () => Navigator.pop(sheetContext), child: const Text('Huỷ')),
                  Expanded(
                    child: Text(
                      title,
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.ink),
                    ),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(sheetContext, selected),
                    child: const Text('Xong', style: TextStyle(fontWeight: FontWeight.w700)),
                  ),
                ],
              ),
            ),
            // Bánh xe có kích thước cố định theo thiết kế của iOS nên giới hạn mức phóng chữ để số không bị cắt.
            MediaQuery.withClampedTextScaling(
              maxScaleFactor: 1.2,
              child: SizedBox(
                height: 216,
                child: CupertinoTheme(
                  data: const CupertinoThemeData(
                    primaryColor: AppColors.primary,
                    textTheme: CupertinoTextThemeData(
                      dateTimePickerTextStyle: TextStyle(fontSize: 24, color: AppColors.ink),
                    ),
                  ),
                  child: CupertinoDatePicker(
                    mode: CupertinoDatePickerMode.time,
                    use24hFormat: true,
                    initialDateTime: DateTime(2000, 1, 1, initial.hour, initial.minute),
                    onDateTimeChanged: (value) => selected = TimeOfDay(hour: value.hour, minute: value.minute),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      );
    },
  );
}
