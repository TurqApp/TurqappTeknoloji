import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/BottomSheets/app_sheet_header.dart';
import 'package:turqappv2/Core/text_styles.dart';
import 'package:turqappv2/Utils/empty_padding.dart';

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
            AppSheetHeader(title: title),
            Expanded(
              child: Align(
                alignment: Alignment.center,
                child: CupertinoTheme(
                  data: CupertinoThemeData(
                    brightness: Brightness.light,
                    textTheme: CupertinoTextThemeData(
                      pickerTextStyle: TextStyle(
                        fontSize: 18,
                        color: Colors.black,
                      ),
                    ),
                  ),
                  child: CupertinoDatePicker(
                    mode: CupertinoDatePickerMode.time,
                    initialDateTime: initialTime,
                    onDateTimeChanged: (DateTime time) {
                      tempPicked = time;
                    },
                    use24hFormat: true,
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
                        'common.cancel'.tr,
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
                      child: Text('common.ok'.tr, style: TextStyles.medium15white),
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
