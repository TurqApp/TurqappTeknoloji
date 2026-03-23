part of 'duration_picker_bottom_sheet.dart';

extension DurationPickerBottomSheetContentPart on DurationPickerBottomSheet {
  Widget _buildSheetContent(
    BuildContext context, {
    required int initialPicked,
    required ValueChanged<int> onDurationChanged,
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
                      pickerTextStyle: TextStyles.bold20Black,
                    ),
                  ),
                  child: CupertinoPicker(
                    itemExtent: 40,
                    onSelectedItemChanged: onDurationChanged,
                    scrollController: FixedExtentScrollController(
                      initialItem: durations.indexOf(initialPicked),
                    ),
                    children: durations
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
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                '',
              ).copyWithText('common.cancel'.tr),
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
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                '',
              ).copyWithText(
                'common.ok'.tr,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

extension on Text {
  Widget copyWithText(
    String text, {
    Color color = Colors.black,
  }) {
    return Text(
      text,
      style: TextStyle(
        color: color,
        fontSize: 15,
        fontFamily: 'MontserratMedium',
      ),
    );
  }
}
