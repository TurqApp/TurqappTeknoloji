import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/BottomSheets/app_sheet_header.dart';
import 'package:turqappv2/Core/text_styles.dart';
import 'package:turqappv2/Modules/Education/Scholarships/CreateScholarship/create_scholarship_controller.dart';

class MultipleChoiceBottomSheet extends StatelessWidget {
  final CreateScholarshipController controller;
  final String title;
  final List<String> items;
  final String? selectionType;
  final String Function(String)? itemLabelBuilder;

  const MultipleChoiceBottomSheet({
    super.key,
    required this.controller,
    required this.title,
    required this.items,
    this.selectionType,
    this.itemLabelBuilder,
  });

  String get _resolvedSelectionType {
    if (selectionType != null) return selectionType!;
    return "";
  }

  @override
  Widget build(BuildContext context) {
    if (_resolvedSelectionType == "months") {
      controller.selectedItems.assignAll(controller.aylar);
    } else if (_resolvedSelectionType == "conditions") {
      controller.selectedItems.assignAll(
        controller.basvuruKosullari.value
            .split('\n')
            .map((item) => item.trim())
            .where((item) => item.isNotEmpty),
      );
    } else if (_resolvedSelectionType == "documents") {
      controller.selectedItems.assignAll(controller.belgeler);
    }

    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          AppSheetHeader(title: title),
          Expanded(
            child: items.isEmpty
                ? Center(child: Text('admin.tasks.not_found'.tr))
                : ListView.builder(
                    itemCount: items.length,
                    itemBuilder: (context, index) {
                      final item = items[index];
                      return GestureDetector(
                        onTap: () {
                          if (controller.selectedItems.contains(item)) {
                            controller.selectedItems.remove(item);
                          } else {
                            controller.selectedItems.add(item);
                          }
                        },
                        child: Container(
                          color: Colors.transparent,
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      itemLabelBuilder?.call(item) ?? item,
                                      style: TextStyles.textFieldTitle.copyWith(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                  Obx(
                                    () => Icon(
                                      controller.selectedItems.contains(item)
                                          ? Icons.check_circle
                                          : Icons.radio_button_unchecked,
                                      color: controller.selectedItems.contains(
                                        item,
                                      )
                                          ? Colors.green
                                          : Colors.grey,
                                      size: 21,
                                    ),
                                  ),
                                ],
                              ),
                              if (index < items.length - 1)
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
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey.shade300,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text("common.cancel".tr,
                      style: TextStyles.textFieldTitle),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    final newItems = controller.selectedItems.join('\n');
                    if (_resolvedSelectionType == "conditions") {
                      final currentText = controller.basvuruKosullari.value;
                      if (currentText.isNotEmpty && newItems.isNotEmpty) {
                        controller.basvuruKosullari.value =
                            '$currentText\n$newItems';
                      } else if (newItems.isNotEmpty) {
                        controller.basvuruKosullari.value = newItems;
                      }
                      controller.basvuruKosullariController.text =
                          controller.localizedConditionsText(
                        controller.basvuruKosullari.value,
                      );
                    } else if (_resolvedSelectionType == "documents") {
                      controller.belgeler.assignAll(controller.selectedItems);
                      controller.belgelerController.text =
                          controller.localizedDocumentsText(
                        controller.selectedItems,
                      );
                    } else if (_resolvedSelectionType == "months") {
                      controller.aylar.assignAll(controller.selectedItems);
                      controller.aylarController.text =
                          controller.selectedItems.join('\n');
                    }
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    "common.select".tr,
                    style: const TextStyle(fontSize: 16, color: Colors.white),
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
