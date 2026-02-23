import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/text_styles.dart';
import 'package:turqappv2/Utils/empty_padding.dart';

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

    return ClipRRect(
      borderRadius: BorderRadius.only(
        topLeft: Radius.circular(20),
        topRight: Radius.circular(20),
      ),
      child: Container(
        padding: EdgeInsets.all(16),
        height: MediaQuery.of(context).size.height / 2.5,
        color: Colors.white,
        child: Column(
          children: [
            Container(
              width: 50,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey,
                borderRadius: BorderRadius.all(Radius.circular(50)),
              ),
            ),
            8.ph,
            Text(title, style: TextStyles.bold20Black),
            Expanded(
              child: Align(
                alignment: Alignment.center,
                child: CupertinoTheme(
                  data: CupertinoThemeData(
                    brightness: Brightness.light,
                    textTheme: CupertinoTextThemeData(
                      pickerTextStyle: TextStyles.bold20Black,
                    ),
                  ),
                  child: CupertinoPicker(
                    itemExtent: 40,
                    onSelectedItemChanged: (int index) {
                      tempPicked = durations[index];
                    },
                    scrollController: FixedExtentScrollController(
                      initialItem: durations.indexOf(tempPicked),
                    ),
                    children:
                        durations
                            .map(
                              (duration) => Center(
                                child: Text(
                                  '$duration dk',
                                  style: TextStyles.bold20Black,
                                ),
                              ),
                            )
                            .toList(),
                  ),
                ),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => Get.back(),
                    child: Container(
                      height: 40,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        "İptal",
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 15,
                          fontFamily: "MontserratMedium",
                        ),
                      ),
                    ),
                  ),
                ),
                8.pw,
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      onSelected(tempPicked);
                      Get.back();
                    },
                    child: Container(
                      height: 40,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: Colors.black,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        "Tamam",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontFamily: "MontserratMedium",
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
