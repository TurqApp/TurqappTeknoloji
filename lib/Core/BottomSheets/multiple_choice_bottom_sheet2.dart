import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/text_styles.dart';

class MultiSelectBottomSheet2 extends StatelessWidget {
  final String title;
  final List<String> items;
  final List<String> selectedItems;
  final Function(List<String>) onConfirm;
  final Map<String, List<String>>? relatedItems;
  final String? parentSelection;

  const MultiSelectBottomSheet2({
    super.key,
    required this.title,
    required this.items,
    required this.selectedItems,
    required this.onConfirm,
    this.relatedItems,
    this.parentSelection,
  });

  @override
  Widget build(BuildContext context) {
    final RxList<String> tempSelectedItems = selectedItems.obs;
    final RxString searchQuery = ''.obs;
    final TextEditingController searchController = TextEditingController();

    RxList<String> filteredItems = <String>[].obs;
    void updateFilteredItems() {
      final baseItems = (relatedItems != null && parentSelection != null)
          ? relatedItems![parentSelection!] ?? items
          : items;
      if (searchQuery.value.isEmpty) {
        filteredItems.assignAll(baseItems);
      } else {
        filteredItems.assignAll(
          baseItems
              .where(
                (item) => item.toLowerCase().contains(
                      searchQuery.value.toLowerCase(),
                    ),
              )
              .toList(),
        );
      }
    }

    ever(searchQuery, (_) => updateFilteredItems());
    updateFilteredItems();

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
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: Colors.grey.withAlpha(50),
              borderRadius: BorderRadius.circular(12),
            ),
            child: TextField(
              controller: searchController,
              decoration: InputDecoration(
                hintText: 'Ara',
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                suffixIcon: Obx(
                  () => searchQuery.value.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, color: Colors.grey),
                          onPressed: () {
                            searchController.clear();
                            searchQuery.value = '';
                          },
                        )
                      : const SizedBox.shrink(),
                ),
              ),
              onChanged: (value) {
                searchQuery.value = value;
              },
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: Obx(
              () => filteredItems.isEmpty
                  ? const Center(
                      child: Text(
                        'Sonuç bulunamadı',
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                    )
                  : ListView.builder(
                      itemCount: filteredItems.length,
                      itemBuilder: (context, index) {
                        final item = filteredItems[index];
                        return GestureDetector(
                          onTap: () {
                            if (item == 'Tüm Üniversiteler') {
                              if (tempSelectedItems.contains(item)) {
                                tempSelectedItems.clear();
                              } else {
                                tempSelectedItems.assignAll([item]);
                              }
                            } else {
                              if (tempSelectedItems.contains(
                                'Tüm Üniversiteler',
                              )) {
                                tempSelectedItems.remove('Tüm Üniversiteler');
                              }
                              if (tempSelectedItems.contains(item)) {
                                tempSelectedItems.remove(item);
                              } else {
                                tempSelectedItems.add(item);
                              }
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 6),
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
                                        style:
                                            TextStyles.textFieldTitle.copyWith(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                    Obx(
                                      () => Icon(
                                        tempSelectedItems.contains(item)
                                            ? Icons.check_circle
                                            : Icons.radio_button_unchecked,
                                        color: tempSelectedItems.contains(item)
                                            ? Colors.green
                                            : Colors.grey,
                                        size: 21,
                                      ),
                                    ),
                                  ],
                                ),
                                if (index < filteredItems.length - 1)
                                  Divider(
                                    color: Colors.grey.withAlpha(50),
                                    thickness: 1,
                                    height: 6,
                                  ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
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
                    onConfirm(tempSelectedItems);
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
