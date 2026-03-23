part of 'future_date_picker_bottom_sheet.dart';

extension FutureDatePickerBottomSheetContentPart
    on FutureDatePickerBottomSheet {
  Widget _buildSheetContent(
    BuildContext context, {
    required DateTime now,
    required DateTime today,
    required DateTime effectiveInitial,
    required DateTime resolvedMaximumDate,
    required ValueChanged<DateTime> onDateChanged,
    required VoidCallback onConfirm,
  }) {
    return ClipRRect(
      borderRadius: const BorderRadius.only(
        topLeft: Radius.circular(20),
        topRight: Radius.circular(20),
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
        height: MediaQuery.of(context).size.height / 2.5,
        color: Colors.white,
        child: Column(
          children: [
            AppSheetHeader(title: title),
            Expanded(
              child: Align(
                alignment: Alignment.center,
                child: CupertinoTheme(
                  data: const CupertinoThemeData(
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
                    onDateTimeChanged: onDateChanged,
                    use24hFormat: true,
                    dateOrder: DatePickerDateOrder.dmy,
                  ),
                ),
              ),
            ),
            _buildFooterActions(onConfirm),
          ],
        ),
      ),
    );
  }

  Widget _buildFooterActions(VoidCallback onConfirm) {
    return Row(
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
                'common.cancel'.tr,
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 15,
                  fontFamily: 'MontserratMedium',
                ),
              ),
            ),
          ),
        ),
        8.pw,
        Expanded(
          child: GestureDetector(
            onTap: onConfirm,
            child: Container(
              height: 40,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'common.ok'.tr,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontFamily: 'MontserratMedium',
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
