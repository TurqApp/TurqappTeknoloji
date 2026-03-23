import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/BottomSheets/app_sheet_header.dart';
import 'package:turqappv2/Core/text_styles.dart';
import 'package:turqappv2/Utils/empty_padding.dart';

part 'duration_picker_bottom_sheet_content_part.dart';

class DurationPickerBottomSheet extends StatelessWidget {
  final int initialDuration;
  final Function(int) onSelected;
  final String title;

  DurationPickerBottomSheet({
    super.key,
    required this.initialDuration,
    required this.onSelected,
    required this.title,
  });

  final List<int> durations = [
    45,
    50,
    55,
    60,
    65,
    65,
    70,
    75,
    80,
    85,
    90,
    95,
    100,
    105,
    110,
    115,
    120,
    125,
    130,
    135,
    140,
    145,
    150,
    155,
    160,
    165,
    170,
    175,
    180,
    185,
    190,
    195,
    200,
    205,
    210,
    215,
    220,
    225,
    230,
    235,
    240,
    245,
    250,
    255,
    260,
    270,
    275,
    280,
    285,
    290,
    295,
    300,
  ];

  @override
  Widget build(BuildContext context) {
    int tempPicked =
        durations.contains(initialDuration) ? initialDuration : durations[0];

    return _buildSheetContent(
      context,
      initialPicked: tempPicked,
      onDurationChanged: (index) => tempPicked = durations[index],
      onConfirm: () {
        onSelected(tempPicked);
        Get.back();
      },
    );
  }
}
