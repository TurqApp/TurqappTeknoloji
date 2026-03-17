import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/BottomSheets/app_sheet_header.dart';
import 'package:turqappv2/Utils/empty_padding.dart';

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
                    mode: CupertinoDatePickerMode.date,
                    initialDateTime: initialDate,
                    maximumDate: maximumDate ?? DateTime.now(),
                    minimumDate: DateTime(1900),
                    onDateTimeChanged: (DateTime date) {
                      tempPicked = date;
                    },
                    use24hFormat: true,
                    dateOrder: DatePickerDateOrder.dmy,
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
                        borderRadius: BorderRadius.circular(12),
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
                        borderRadius: BorderRadius.circular(12),
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
