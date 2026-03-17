import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/BottomSheets/app_sheet_header.dart';
import 'package:turqappv2/Utils/empty_padding.dart';

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
                    mode: withTime
                        ? CupertinoDatePickerMode.dateAndTime
                        : CupertinoDatePickerMode.date,
                    initialDateTime: effectiveInitial,
                    minimumDate: withTime ? now : today,
                    maximumDate: resolvedMaximumDate,
                    onDateTimeChanged: (DateTime date) {
                      tempPicked =
                          withTime ? _clampPickedDate(date, now) : date;
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
                      onSelected(withTime
                          ? _clampPickedDate(tempPicked, now)
                          : tempPicked);
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
