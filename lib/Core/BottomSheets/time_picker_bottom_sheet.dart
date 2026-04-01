import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/BottomSheets/app_sheet_header.dart';
import 'package:turqappv2/Core/text_styles.dart';
import 'package:turqappv2/Utils/empty_padding.dart';

part 'time_picker_bottom_sheet_content_part.dart';

class FutureTimePickerBottomSheet extends StatelessWidget {
  final DateTime initialTime;
  final Function(DateTime) onSelected;
  final String title;

  FutureTimePickerBottomSheet({
    super.key,
    DateTime? initialTime,
    required this.onSelected,
    required this.title,
  }) : initialTime = initialTime ?? DateTime.now();

  @override
  Widget build(BuildContext context) {
    DateTime tempPicked = initialTime;

    return _buildSheetContent(
      context,
      onTimeChanged: (time) => tempPicked = time,
      onConfirm: () {
        onSelected(tempPicked);
        Get.back();
      },
    );
  }
}
