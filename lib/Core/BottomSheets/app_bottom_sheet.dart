import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/BottomSheets/app_sheet_header.dart';

class AppBottomSheet extends StatelessWidget {
  final List<dynamic> list;
  final Function(dynamic) onBackData;
  final Function(List<dynamic>)? onBackUpdatedList;
  final String title;
  final dynamic startSelection;
  final String Function(dynamic)? itemLabelBuilder;

  const AppBottomSheet({
    required this.list,
    required this.onBackData,
    required this.title,
    required this.startSelection,
    this.itemLabelBuilder,
    this.onBackUpdatedList,
    super.key,
  });

  static Future<void> show({
    required BuildContext context,
    required List<dynamic> items,
    required String title,
    required Function(dynamic) onSelect,
    dynamic selectedItem,
    bool isSearchable = false,
    String Function(dynamic)? itemLabelBuilder,
  }) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25.0)),
      ),
      builder: (BuildContext context) {
        return AppBottomSheet(
          list: items,
          title: title,
          startSelection: selectedItem,
          onBackData: onSelect,
          itemLabelBuilder: itemLabelBuilder,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(AppBottomSheetController());
    controller.initSelection(list, startSelection);

    return Padding(
      padding: EdgeInsets.all(15),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppSheetHeader(title: title),
          Wrap(
            children: [
              SizedBox(
                width: double.infinity,
                child: Obx(
                  () => ListView.builder(
                    shrinkWrap: true,
                    itemCount: controller.list.length,
                    itemBuilder: (context, index) {
                      final item = controller.list[index];
                      final isLastItem = index == controller.list.length - 1;

                      return GestureDetector(
                        onTap: () {
                          controller.selectItem(item, onBackData);
                          if (onBackUpdatedList != null) {
                            onBackUpdatedList!(controller.list.toList());
                          }
                        },
                        child: Container(
                          color: Colors.transparent,
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      itemLabelBuilder?.call(item) ??
                                          item.toString(),
                                      style: TextStyle(
                                        color: Colors.black,
                                        fontSize: 16,
                                        fontFamily: "Montserrat",
                                      ),
                                    ),
                                  ),
                                  SizedBox(width: 12),
                                  Icon(
                                    controller.startSelection.value == item
                                        ? Icons.check_circle
                                        : Icons.radio_button_unchecked,
                                    color:
                                        controller.startSelection.value == item
                                            ? Colors.green
                                            : Colors.grey,
                                    size: 21,
                                  ),
                                ],
                              ),
                              if (!isLastItem)
                                Divider(
                                  color: Colors.grey.withAlpha(50),
                                  thickness: 1,
                                  height: 20,
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class AppBottomSheetController extends GetxController {
  final list = <dynamic>[].obs;
  final startSelection = "".obs;

  void initSelection(List<dynamic> items, dynamic initialSelection) {
    list.value = items;
    startSelection.value = initialSelection?.toString() ?? "";
  }

  void selectItem(dynamic item, Function(dynamic) onBackData) {
    startSelection.value = item.toString();
    onBackData(item);
    Get.back();
  }
}
