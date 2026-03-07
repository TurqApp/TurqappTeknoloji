import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/text_styles.dart';
import 'package:turqappv2/Modules/Education/Scholarships/CreateScholarship/create_scholarship_controller.dart';

class MultipleChoiceBottomSheet extends StatelessWidget {
  final CreateScholarshipController controller;
  final String title;
  final List<String> items;

  const MultipleChoiceBottomSheet({
    super.key,
    required this.controller,
    required this.title,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    if (title == "Burs Verilecek Aylar") {
      controller.selectedItems.assignAll(controller.aylar);
    } else if (title == "Başvuru Koşulları") {
      controller.selectedItems.clear();
    } else if (title == "Gerekli Belgeler") {
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
          Container(
            width: 50,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey,
              borderRadius: BorderRadius.all(Radius.circular(50)),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: TextStyles.textFieldTitle.copyWith(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          Expanded(
            child: items.isEmpty
                ? const Center(child: Text("Bulunamadı"))
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
                                      item,
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
                  child: Text("İptal", style: TextStyles.textFieldTitle),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    final newItems = controller.selectedItems.join('\n');
                    if (title == "Başvuru Koşulları") {
                      final currentText = controller.basvuruKosullari.value;
                      if (currentText.isNotEmpty && newItems.isNotEmpty) {
                        controller.basvuruKosullari.value =
                            '$currentText\n$newItems';
                      } else if (newItems.isNotEmpty) {
                        controller.basvuruKosullari.value = newItems;
                      }
                      controller.basvuruKosullariController.text =
                          controller.basvuruKosullari.value;
                    } else if (title == "Gerekli Belgeler") {
                      controller.belgeler.assignAll(controller.selectedItems);
                      controller.belgelerController.text =
                          controller.selectedItems.join('\n');
                    } else if (title == "Burs Verilecek Aylar") {
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
                  child: const Text(
                    "Seç",
                    style: TextStyle(fontSize: 16, color: Colors.white),
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
