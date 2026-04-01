import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/BottomSheets/app_sheet_header.dart';
import 'package:turqappv2/Utils/empty_padding.dart';

part 'date_picker_bottom_sheet_content_part.dart';

class DatePickerBottomSheet extends StatelessWidget {
  final DateTime initialDate;
  final DateTime? maximumDate;
  final Function(DateTime) onSelected;
  final String title;

  DatePickerBottomSheet({
    super.key,
    DateTime? initialDate,
    required this.onSelected,
    this.maximumDate,
    required this.title,
  }) : initialDate = initialDate ?? DateTime.now();

  @override
  Widget build(BuildContext context) {
    DateTime tempPicked = initialDate;

    return _buildSheetContent(
      context,
      onDateChanged: (date) => tempPicked = date,
      onConfirm: () {
        onSelected(tempPicked);
        Get.back();
      },
    );
  }
}
