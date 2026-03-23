import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/BottomSheets/app_sheet_header.dart';
import 'package:turqappv2/Utils/empty_padding.dart';

part 'future_date_picker_bottom_sheet_content_part.dart';

class FutureDatePickerBottomSheet extends StatelessWidget {
  final DateTime initialDate;
  final DateTime? maximumDate;
  final Function(DateTime) onSelected;
  final String title;
  final bool withTime;

  FutureDatePickerBottomSheet({
    super.key,
    DateTime? initialDate,
    required this.onSelected,
    this.maximumDate,
    required this.title,
    this.withTime = false,
  }) : initialDate = initialDate ?? DateTime.now();

  DateTime _stripTime(DateTime dt) => DateTime(dt.year, dt.month, dt.day);

  DateTime _resolveMaximumDate(DateTime now) =>
      maximumDate ?? now.add(const Duration(days: 90));

  DateTime _clampPickedDate(DateTime picked, DateTime now) {
    final max = _resolveMaximumDate(now);
    if (picked.isBefore(now)) return now;
    if (picked.isAfter(max)) return max;
    return picked;
  }

  @override
  Widget build(BuildContext context) {
    final DateTime now = DateTime.now();
    final DateTime today = _stripTime(now);
    final DateTime resolvedMaximumDate = _resolveMaximumDate(now);

    final DateTime effectiveInitial = withTime
        ? _clampPickedDate(initialDate, now)
        : (() {
            var d = _stripTime(initialDate);
            if (d.isBefore(today)) d = today;
            final maxDay = _stripTime(resolvedMaximumDate);
            if (d.isAfter(maxDay)) d = maxDay;
            return d;
          })();

    DateTime tempPicked = effectiveInitial;

    return _buildSheetContent(
      context,
      now: now,
      today: today,
      effectiveInitial: effectiveInitial,
      resolvedMaximumDate: resolvedMaximumDate,
      onDateChanged: (date) {
        tempPicked = withTime ? _clampPickedDate(date, now) : date;
      },
      onConfirm: () {
        onSelected(withTime ? _clampPickedDate(tempPicked, now) : tempPicked);
        Get.back();
      },
    );
  }
}
