import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/BottomSheets/app_sheet_header.dart';
import 'package:turqappv2/Core/Utils/text_normalization_utils.dart';
import 'package:turqappv2/Core/text_styles.dart';

class MultiSelectBottomSheet2 extends StatelessWidget {
  static const String _allUniversitiesKey = 'scholarship.all_universities';
  static const String _allUniversitiesValue = 'Tüm Üniversiteler';
  final String title;
  final List<String> items;
  final List<String> selectedItems;
  final Function(List<String>) onConfirm;
  final Map<String, List<String>>? relatedItems;
  final String? parentSelection;
  final String Function(String)? itemLabelBuilder;

  const MultiSelectBottomSheet2({
    super.key,
    required this.title,
    required this.items,
    required this.selectedItems,
    required this.onConfirm,
    this.relatedItems,
    this.parentSelection,
    this.itemLabelBuilder,
  });

  bool _isAllUniversitiesValue(String value) {
    final normalized = value.trim();
    return const <String>{
      _allUniversitiesValue,
      _allUniversitiesKey,
      'All Universities',
      'Alle Universitäten',
      'Toutes les universités',
      'Tutte le università',
      'Все университеты',
    }.contains(normalized);
  }

  bool _containsSelectedValue(List<String> values, String item) {
    if (_isAllUniversitiesValue(item)) {
      return values.any(_isAllUniversitiesValue);
    }
    return values.contains(item);
  }

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
        final normalizedQuery = normalizeSearchText(searchQuery.value);
        filteredItems.assignAll(
          baseItems
              .where(
                (item) =>
                    normalizeSearchText(item).contains(normalizedQuery),
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
          AppSheetHeader(
            title: title,
            padding: const EdgeInsets.only(bottom: 12),
          ),
          Container(
            decoration: BoxDecoration(
              color: Colors.grey.withAlpha(50),
              borderRadius: BorderRadius.circular(12),
            ),
            child: TextField(
              controller: searchController,
              decoration: InputDecoration(
                hintText: 'common.search'.tr,
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
                  ? Center(
                      child: Text(
                        'explore.no_results'.tr,
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.grey,
                        ),
                      ),
                    )
                  : ListView.builder(
                      itemCount: filteredItems.length,
                      itemBuilder: (context, index) {
                        final item = filteredItems[index];
                        return GestureDetector(
                          onTap: () {
                            final isAllUniversities =
                                _isAllUniversitiesValue(item);
                            if (isAllUniversities) {
                              if (_containsSelectedValue(
                                tempSelectedItems,
                                item,
                              )) {
                                tempSelectedItems.clear();
                              } else {
                                tempSelectedItems.assignAll(
                                  <String>[_allUniversitiesValue],
                                );
                              }
                            } else {
                              tempSelectedItems.removeWhere(
                                _isAllUniversitiesValue,
                              );
                              if (_containsSelectedValue(
                                tempSelectedItems,
                                item,
                              )) {
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
                                        itemLabelBuilder?.call(item) ?? item,
                                        style:
                                            TextStyles.textFieldTitle.copyWith(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                    Obx(
                                      () => Icon(
                                        _containsSelectedValue(
                                          tempSelectedItems,
                                          item,
                                        )
                                            ? Icons.check_circle
                                            : Icons.radio_button_unchecked,
                                        color: _containsSelectedValue(
                                          tempSelectedItems,
                                          item,
                                        )
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
                  child: Text("common.cancel".tr,
                      style: TextStyles.textFieldTitle),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    if (tempSelectedItems.any(_isAllUniversitiesValue)) {
                      onConfirm(<String>[_allUniversitiesValue]);
                    } else {
                      onConfirm(tempSelectedItems);
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
